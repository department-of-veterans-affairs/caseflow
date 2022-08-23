// Copyright 2009 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "v8.h"

#include "api.h"
#include "global-handles.h"

#include "vm-state-inl.h"

namespace v8 {
namespace internal {


ObjectGroup::~ObjectGroup() {
  if (info_ != NULL) info_->Dispose();
}


class GlobalHandles::Node {
 public:
  // State transition diagram:
  // FREE -> NORMAL <-> WEAK -> PENDING -> NEAR_DEATH -> { NORMAL, WEAK, FREE }
  enum State {
    FREE = 0,
    NORMAL,     // Normal global handle.
    WEAK,       // Flagged as weak but not yet finalized.
    PENDING,    // Has been recognized as only reachable by weak handles.
    NEAR_DEATH  // Callback has informed the handle is near death.
  };

  // Maps handle location (slot) to the containing node.
  static Node* FromLocation(Object** location) {
    ASSERT(OFFSET_OF(Node, object_) == 0);
    return reinterpret_cast<Node*>(location);
  }

  Node() {
    ASSERT(OFFSET_OF(Node, class_id_) == Internals::kNodeClassIdOffset);
    ASSERT(OFFSET_OF(Node, flags_) == Internals::kNodeFlagsOffset);
    STATIC_ASSERT(static_cast<int>(NodeState::kMask) ==
                  Internals::kNodeStateMask);
    STATIC_ASSERT(WEAK == Internals::kNodeStateIsWeakValue);
    STATIC_ASSERT(NEAR_DEATH == Internals::kNodeStateIsNearDeathValue);
    STATIC_ASSERT(static_cast<int>(IsIndependent::kShift) ==
                  Internals::kNodeIsIndependentShift);
    STATIC_ASSERT(static_cast<int>(IsPartiallyDependent::kShift) ==
                  Internals::kNodeIsPartiallyDependentShift);
  }

#ifdef DEBUG
  ~Node() {
    // TODO(1428): if it's a weak handle we should have invoked its callback.
    // Zap the values for eager trapping.
    object_ = NULL;
    class_id_ = v8::HeapProfiler::kPersistentHandleNoClassId;
    index_ = 0;
    set_independent(false);
    set_partially_dependent(false);
    set_in_new_space_list(false);
    parameter_or_next_free_.next_free = NULL;
    weak_reference_callback_ = NULL;
    near_death_callback_ = NULL;
  }
#endif

  void Initialize(int index, Node** first_free) {
    index_ = static_cast<uint8_t>(index);
    ASSERT(static_cast<int>(index_) == index);
    set_state(FREE);
    set_in_new_space_list(false);
    parameter_or_next_free_.next_free = *first_free;
    *first_free = this;
  }

  void Acquire(Object* object, GlobalHandles* global_handles) {
    ASSERT(state() == FREE);
    object_ = object;
    class_id_ = v8::HeapProfiler::kPersistentHandleNoClassId;
    set_independent(false);
    set_partially_dependent(false);
    set_state(NORMAL);
    parameter_or_next_free_.parameter = NULL;
    weak_reference_callback_ = NULL;
    near_death_callback_ = NULL;
    IncreaseBlockUses(global_handles);
  }

  void Release(GlobalHandles* global_handles) {
    ASSERT(state() != FREE);
    set_state(FREE);
    parameter_or_next_free_.next_free = global_handles->first_free_;
    global_handles->first_free_ = this;
    DecreaseBlockUses(global_handles);
  }

  // Object slot accessors.
  Object* object() const { return object_; }
  Object** location() { return &object_; }
  Handle<Object> handle() { return Handle<Object>(location()); }

  // Wrapper class ID accessors.
  bool has_wrapper_class_id() const {
    return class_id_ != v8::HeapProfiler::kPersistentHandleNoClassId;
  }

  uint16_t wrapper_class_id() const { return class_id_; }

  // State and flag accessors.

  State state() const {
    return NodeState::decode(flags_);
  }
  void set_state(State state) {
    flags_ = NodeState::update(flags_, state);
  }

  bool is_independent() {
    return IsIndependent::decode(flags_);
  }
  void set_independent(bool v) {
    flags_ = IsIndependent::update(flags_, v);
  }

  bool is_partially_dependent() {
    return IsPartiallyDependent::decode(flags_);
  }
  void set_partially_dependent(bool v) {
    flags_ = IsPartiallyDependent::update(flags_, v);
  }

  bool is_in_new_space_list() {
    return IsInNewSpaceList::decode(flags_);
  }
  void set_in_new_space_list(bool v) {
    flags_ = IsInNewSpaceList::update(flags_, v);
  }

  bool IsNearDeath() const {
    // Check for PENDING to ensure correct answer when processing callbacks.
    return state() == PENDING || state() == NEAR_DEATH;
  }

  bool IsWeak() const { return state() == WEAK; }

  bool IsRetainer() const { return state() != FREE; }

  bool IsStrongRetainer() const { return state() == NORMAL; }

  bool IsWeakRetainer() const {
    return state() == WEAK || state() == PENDING || state() == NEAR_DEATH;
  }

  void MarkPending() {
    ASSERT(state() == WEAK);
    set_state(PENDING);
  }

  // Independent flag accessors.
  void MarkIndependent() {
    ASSERT(state() != FREE);
    set_independent(true);
  }

  void MarkPartiallyDependent(GlobalHandles* global_handles) {
    ASSERT(state() != FREE);
    if (global_handles->isolate()->heap()->InNewSpace(object_)) {
      set_partially_dependent(true);
    }
  }
  void clear_partially_dependent() { set_partially_dependent(false); }

  // Callback accessor.
  // TODO(svenpanne) Re-enable or nuke later.
  // WeakReferenceCallback callback() { return callback_; }

  // Callback parameter accessors.
  void set_parameter(void* parameter) {
    ASSERT(state() != FREE);
    parameter_or_next_free_.parameter = parameter;
  }
  void* parameter() const {
    ASSERT(state() != FREE);
    return parameter_or_next_free_.parameter;
  }

  // Accessors for next free node in the free list.
  Node* next_free() {
    ASSERT(state() == FREE);
    return parameter_or_next_free_.next_free;
  }
  void set_next_free(Node* value) {
    ASSERT(state() == FREE);
    parameter_or_next_free_.next_free = value;
  }

  void MakeWeak(GlobalHandles* global_handles,
                void* parameter,
                WeakReferenceCallback weak_reference_callback,
                NearDeathCallback near_death_callback) {
    ASSERT(state() != FREE);
    set_state(WEAK);
    set_parameter(parameter);
    weak_reference_callback_ = weak_reference_callback;
    near_death_callback_ = near_death_callback;
  }

  void ClearWeakness(GlobalHandles* global_handles) {
    ASSERT(state() != FREE);
    set_state(NORMAL);
    set_parameter(NULL);
  }

  bool PostGarbageCollectionProcessing(Isolate* isolate,
                                       GlobalHandles* global_handles) {
    if (state() != Node::PENDING) return false;
    if (weak_reference_callback_ == NULL &&
        near_death_callback_ == NULL) {
      Release(global_handles);
      return false;
    }
    void* par = parameter();
    set_state(NEAR_DEATH);
    set_parameter(NULL);

    v8::Persistent<v8::Object> object = ToApi<v8::Object>(handle());
    {
      // Check that we are not passing a finalized external string to
      // the callback.
      ASSERT(!object_->IsExternalAsciiString() ||
             ExternalAsciiString::cast(object_)->resource() != NULL);
      ASSERT(!object_->IsExternalTwoByteString() ||
             ExternalTwoByteString::cast(object_)->resource() != NULL);
      // Leaving V8.
      VMState state(isolate, EXTERNAL);
      if (weak_reference_callback_ != NULL) {
        weak_reference_callback_(object, par);
      }
      if (near_death_callback_ != NULL) {
        near_death_callback_(reinterpret_cast<v8::Isolate*>(isolate),
                             object,
                             par);
      }
    }
    // Absence of explicit cleanup or revival of weak handle
    // in most of the cases would lead to memory leak.
    ASSERT(state() != NEAR_DEATH);
    return true;
  }

 private:
  inline NodeBlock* FindBlock();
  inline void IncreaseBlockUses(GlobalHandles* global_handles);
  inline void DecreaseBlockUses(GlobalHandles* global_handles);

  // Storage for object pointer.
  // Placed first to avoid offset computation.
  Object* object_;

  // Next word stores class_id, index, state, and independent.
  // Note: the most aligned fields should go first.

  // Wrapper class ID.
  uint16_t class_id_;

  // Index in the containing handle block.
  uint8_t index_;

  // This stores three flags (independent, partially_dependent and
  // in_new_space_list) and a State.
  class NodeState:            public BitField<State, 0, 4> {};
  class IsIndependent:        public BitField<bool,  4, 1> {};
  class IsPartiallyDependent: public BitField<bool,  5, 1> {};
  class IsInNewSpaceList:     public BitField<bool,  6, 1> {};

  uint8_t flags_;

  // Handle specific callback.
  WeakReferenceCallback weak_reference_callback_;
  NearDeathCallback near_death_callback_;

  // Provided data for callback.  In FREE state, this is used for
  // the free list link.
  union {
    void* parameter;
    Node* next_free;
  } parameter_or_next_free_;

  DISALLOW_COPY_AND_ASSIGN(Node);
};


class GlobalHandles::NodeBlock {
 public:
  static const int kSize = 256;

  explicit NodeBlock(NodeBlock* next)
      : next_(next), used_nodes_(0), next_used_(NULL), prev_used_(NULL) {}

  void PutNodesOnFreeList(Node** first_free) {
    for (int i = kSize - 1; i >= 0; --i) {
      nodes_[i].Initialize(i, first_free);
    }
  }

  Node* node_at(int index) {
    ASSERT(0 <= index && index < kSize);
    return &nodes_[index];
  }

  void IncreaseUses(GlobalHandles* global_handles) {
    ASSERT(used_nodes_ < kSize);
    if (used_nodes_++ == 0) {
      NodeBlock* old_first = global_handles->first_used_block_;
      global_handles->first_used_block_ = this;
      next_used_ = old_first;
      prev_used_ = NULL;
      if (old_first == NULL) return;
      old_first->prev_used_ = this;
    }
  }

  void DecreaseUses(GlobalHandles* global_handles) {
    ASSERT(used_nodes_ > 0);
    if (--used_nodes_ == 0) {
      if (next_used_ != NULL) next_used_->prev_used_ = prev_used_;
      if (prev_used_ != NULL) prev_used_->next_used_ = next_used_;
      if (this == global_handles->first_used_block_) {
        global_handles->first_used_block_ = next_used_;
      }
    }
  }

  // Next block in the list of all blocks.
  NodeBlock* next() const { return next_; }

  // Next/previous block in the list of blocks with used nodes.
  NodeBlock* next_used() const { return next_used_; }
  NodeBlock* prev_used() const { return prev_used_; }

 private:
  Node nodes_[kSize];
  NodeBlock* const next_;
  int used_nodes_;
  NodeBlock* next_used_;
  NodeBlock* prev_used_;
};


GlobalHandles::NodeBlock* GlobalHandles::Node::FindBlock() {
  intptr_t ptr = reinterpret_cast<intptr_t>(this);
  ptr = ptr - index_ * sizeof(Node);
  NodeBlock* block = reinterpret_cast<NodeBlock*>(ptr);
  ASSERT(block->node_at(index_) == this);
  return block;
}


void GlobalHandles::Node::IncreaseBlockUses(GlobalHandles* global_handles) {
  FindBlock()->IncreaseUses(global_handles);
}


void GlobalHandles::Node::DecreaseBlockUses(GlobalHandles* global_handles) {
  FindBlock()->DecreaseUses(global_handles);
}


class GlobalHandles::NodeIterator {
 public:
  explicit NodeIterator(GlobalHandles* global_handles)
      : block_(global_handles->first_used_block_),
        index_(0) {}

  bool done() const { return block_ == NULL; }

  Node* node() const {
    ASSERT(!done());
    return block_->node_at(index_);
  }

  void Advance() {
    ASSERT(!done());
    if (++index_ < NodeBlock::kSize) return;
    index_ = 0;
    block_ = block_->next_used();
  }

 private:
  NodeBlock* block_;
  int index_;

  DISALLOW_COPY_AND_ASSIGN(NodeIterator);
};


GlobalHandles::GlobalHandles(Isolate* isolate)
    : isolate_(isolate),
      number_of_global_handles_(0),
      first_block_(NULL),
      first_used_block_(NULL),
      first_free_(NULL),
      post_gc_processing_count_(0) {}


GlobalHandles::~GlobalHandles() {
  NodeBlock* block = first_block_;
  while (block != NULL) {
    NodeBlock* tmp = block->next();
    delete block;
    block = tmp;
  }
  first_block_ = NULL;
}


Handle<Object> GlobalHandles::Create(Object* value) {
  isolate_->counters()->global_handles()->Increment();
  number_of_global_handles_++;
  if (first_free_ == NULL) {
    first_block_ = new NodeBlock(first_block_);
    first_block_->PutNodesOnFreeList(&first_free_);
  }
  ASSERT(first_free_ != NULL);
  // Take the first node in the free list.
  Node* result = first_free_;
  first_free_ = result->next_free();
  result->Acquire(value, this);
  if (isolate_->heap()->InNewSpace(value) &&
      !result->is_in_new_space_list()) {
    new_space_nodes_.Add(result);
    result->set_in_new_space_list(true);
  }
  return result->handle();
}


void GlobalHandles::Destroy(Object** location) {
  isolate_->counters()->global_handles()->Decrement();
  number_of_global_handles_--;
  if (location == NULL) return;
  Node::FromLocation(location)->Release(this);
}


void GlobalHandles::MakeWeak(Object** location,
                             void* parameter,
                             WeakReferenceCallback weak_reference_callback,
                             NearDeathCallback near_death_callback) {
  ASSERT((weak_reference_callback != NULL) !=
         (near_death_callback != NULL));
  Node::FromLocation(location)->MakeWeak(this,
                                         parameter,
                                         weak_reference_callback,
                                         near_death_callback);
}


void GlobalHandles::ClearWeakness(Object** location) {
  Node::FromLocation(location)->ClearWeakness(this);
}


void GlobalHandles::MarkIndependent(Object** location) {
  Node::FromLocation(location)->MarkIndependent();
}


void GlobalHandles::MarkPartiallyDependent(Object** location) {
  Node::FromLocation(location)->MarkPartiallyDependent(this);
}


bool GlobalHandles::IsIndependent(Object** location) {
  return Node::FromLocation(location)->is_independent();
}


bool GlobalHandles::IsNearDeath(Object** location) {
  return Node::FromLocation(location)->IsNearDeath();
}


bool GlobalHandles::IsWeak(Object** location) {
  return Node::FromLocation(location)->IsWeak();
}


void GlobalHandles::IterateWeakRoots(ObjectVisitor* v) {
  for (NodeIterator it(this); !it.done(); it.Advance()) {
    if (it.node()->IsWeakRetainer()) v->VisitPointer(it.node()->location());
  }
}


void GlobalHandles::IdentifyWeakHandles(WeakSlotCallback f) {
  for (NodeIterator it(this); !it.done(); it.Advance()) {
    if (it.node()->IsWeak() && f(it.node()->location())) {
      it.node()->MarkPending();
    }
  }
}


void GlobalHandles::IterateNewSpaceStrongAndDependentRoots(ObjectVisitor* v) {
  for (int i = 0; i < new_space_nodes_.length(); ++i) {
    Node* node = new_space_nodes_[i];
    if (node->IsStrongRetainer() ||
        (node->IsWeakRetainer() && !node->is_independent() &&
         !node->is_partially_dependent())) {
        v->VisitPointer(node->location());
    }
  }
}


void GlobalHandles::IdentifyNewSpaceWeakIndependentHandles(
    WeakSlotCallbackWithHeap f) {
  for (int i = 0; i < new_space_nodes_.length(); ++i) {
    Node* node = new_space_nodes_[i];
    ASSERT(node->is_in_new_space_list());
    if ((node->is_independent() || node->is_partially_dependent()) &&
        node->IsWeak() && f(isolate_->heap(), node->location())) {
      node->MarkPending();
    }
  }
}


void GlobalHandles::IterateNewSpaceWeakIndependentRoots(ObjectVisitor* v) {
  for (int i = 0; i < new_space_nodes_.length(); ++i) {
    Node* node = new_space_nodes_[i];
    ASSERT(node->is_in_new_space_list());
    if ((node->is_independent() || node->is_partially_dependent()) &&
        node->IsWeakRetainer()) {
      v->VisitPointer(node->location());
    }
  }
}


bool GlobalHandles::IterateObjectGroups(ObjectVisitor* v,
                                        WeakSlotCallbackWithHeap can_skip) {
  int last = 0;
  bool any_group_was_visited = false;
  for (int i = 0; i < object_groups_.length(); i++) {
    ObjectGroup* entry = object_groups_.at(i);
    ASSERT(entry != NULL);

    Object*** objects = entry->objects_;
    bool group_should_be_visited = false;
    for (size_t j = 0; j < entry->length_; j++) {
      Object* object = *objects[j];
      if (object->IsHeapObject()) {
        if (!can_skip(isolate_->heap(), &object)) {
          group_should_be_visited = true;
          break;
        }
      }
    }

    if (!group_should_be_visited) {
      object_groups_[last++] = entry;
      continue;
    }

    // An object in the group requires visiting, so iterate over all
    // objects in the group.
    for (size_t j = 0; j < entry->length_; ++j) {
      Object* object = *objects[j];
      if (object->IsHeapObject()) {
        v->VisitPointer(&object);
        any_group_was_visited = true;
      }
    }

    // Once the entire group has been iterated over, set the object
    // group to NULL so it won't be processed again.
    entry->Dispose();
    object_groups_.at(i) = NULL;
  }
  object_groups_.Rewind(last);
  return any_group_was_visited;
}


bool GlobalHandles::PostGarbageCollectionProcessing(
    GarbageCollector collector, GCTracer* tracer) {
  // Process weak global handle callbacks. This must be done after the
  // GC is completely done, because the callbacks may invoke arbitrary
  // API functions.
  ASSERT(isolate_->heap()->gc_state() == Heap::NOT_IN_GC);
  const int initial_post_gc_processing_count = ++post_gc_processing_count_;
  bool next_gc_likely_to_collect_more = false;
  if (collector == SCAVENGER) {
    for (int i = 0; i < new_space_nodes_.length(); ++i) {
      Node* node = new_space_nodes_[i];
      ASSERT(node->is_in_new_space_list());
      // Skip dependent handles. Their weak callbacks might expect to be
      // called between two global garbage collection callbacks which
      // are not called for minor collections.
      if (!node->is_independent() && !node->is_partially_dependent()) {
        continue;
      }
      node->clear_partially_dependent();
      if (node->PostGarbageCollectionProcessing(isolate_, this)) {
        if (initial_post_gc_processing_count != post_gc_processing_count_) {
          // Weak callback triggered another GC and another round of
          // PostGarbageCollection processing.  The current node might
          // have been deleted in that round, so we need to bail out (or
          // restart the processing).
          return next_gc_likely_to_collect_more;
        }
      }
      if (!node->IsRetainer()) {
        next_gc_likely_to_collect_more = true;
      }
    }
  } else {
    for (NodeIterator it(this); !it.done(); it.Advance()) {
      it.node()->clear_partially_dependent();
      if (it.node()->PostGarbageCollectionProcessing(isolate_, this)) {
        if (initial_post_gc_processing_count != post_gc_processing_count_) {
          // See the comment above.
          return next_gc_likely_to_collect_more;
        }
      }
      if (!it.node()->IsRetainer()) {
        next_gc_likely_to_collect_more = true;
      }
    }
  }
  // Update the list of new space nodes.
  int last = 0;
  for (int i = 0; i < new_space_nodes_.length(); ++i) {
    Node* node = new_space_nodes_[i];
    ASSERT(node->is_in_new_space_list());
    if (node->IsRetainer()) {
      if (isolate_->heap()->InNewSpace(node->object())) {
        new_space_nodes_[last++] = node;
        tracer->increment_nodes_copied_in_new_space();
      } else {
        node->set_in_new_space_list(false);
        tracer->increment_nodes_promoted();
      }
    } else {
      node->set_in_new_space_list(false);
      tracer->increment_nodes_died_in_new_space();
    }
  }
  new_space_nodes_.Rewind(last);
  return next_gc_likely_to_collect_more;
}


void GlobalHandles::IterateStrongRoots(ObjectVisitor* v) {
  for (NodeIterator it(this); !it.done(); it.Advance()) {
    if (it.node()->IsStrongRetainer()) {
      v->VisitPointer(it.node()->location());
    }
  }
}


void GlobalHandles::IterateAllRoots(ObjectVisitor* v) {
  for (NodeIterator it(this); !it.done(); it.Advance()) {
    if (it.node()->IsRetainer()) {
      v->VisitPointer(it.node()->location());
    }
  }
}


void GlobalHandles::IterateAllRootsWithClassIds(ObjectVisitor* v) {
  for (NodeIterator it(this); !it.done(); it.Advance()) {
    if (it.node()->IsRetainer() && it.node()->has_wrapper_class_id()) {
      v->VisitEmbedderReference(it.node()->location(),
                                it.node()->wrapper_class_id());
    }
  }
}


void GlobalHandles::IterateAllRootsInNewSpaceWithClassIds(ObjectVisitor* v) {
  for (int i = 0; i < new_space_nodes_.length(); ++i) {
    Node* node = new_space_nodes_[i];
    if (node->IsRetainer() && node->has_wrapper_class_id()) {
      v->VisitEmbedderReference(node->location(),
                                node->wrapper_class_id());
    }
  }
}


int GlobalHandles::NumberOfWeakHandles() {
  int count = 0;
  for (NodeIterator it(this); !it.done(); it.Advance()) {
    if (it.node()->IsWeakRetainer()) {
      count++;
    }
  }
  return count;
}


int GlobalHandles::NumberOfGlobalObjectWeakHandles() {
  int count = 0;
  for (NodeIterator it(this); !it.done(); it.Advance()) {
    if (it.node()->IsWeakRetainer() &&
        it.node()->object()->IsJSGlobalObject()) {
      count++;
    }
  }
  return count;
}


void GlobalHandles::RecordStats(HeapStats* stats) {
  *stats->global_handle_count = 0;
  *stats->weak_global_handle_count = 0;
  *stats->pending_global_handle_count = 0;
  *stats->near_death_global_handle_count = 0;
  *stats->free_global_handle_count = 0;
  for (NodeIterator it(this); !it.done(); it.Advance()) {
    *stats->global_handle_count += 1;
    if (it.node()->state() == Node::WEAK) {
      *stats->weak_global_handle_count += 1;
    } else if (it.node()->state() == Node::PENDING) {
      *stats->pending_global_handle_count += 1;
    } else if (it.node()->state() == Node::NEAR_DEATH) {
      *stats->near_death_global_handle_count += 1;
    } else if (it.node()->state() == Node::FREE) {
      *stats->free_global_handle_count += 1;
    }
  }
}

#ifdef DEBUG

void GlobalHandles::PrintStats() {
  int total = 0;
  int weak = 0;
  int pending = 0;
  int near_death = 0;
  int destroyed = 0;

  for (NodeIterator it(this); !it.done(); it.Advance()) {
    total++;
    if (it.node()->state() == Node::WEAK) weak++;
    if (it.node()->state() == Node::PENDING) pending++;
    if (it.node()->state() == Node::NEAR_DEATH) near_death++;
    if (it.node()->state() == Node::FREE) destroyed++;
  }

  PrintF("Global Handle Statistics:\n");
  PrintF("  allocated memory = %" V8_PTR_PREFIX "dB\n", sizeof(Node) * total);
  PrintF("  # weak       = %d\n", weak);
  PrintF("  # pending    = %d\n", pending);
  PrintF("  # near_death = %d\n", near_death);
  PrintF("  # free       = %d\n", destroyed);
  PrintF("  # total      = %d\n", total);
}

void GlobalHandles::Print() {
  PrintF("Global handles:\n");
  for (NodeIterator it(this); !it.done(); it.Advance()) {
    PrintF("  handle %p to %p%s\n",
           reinterpret_cast<void*>(it.node()->location()),
           reinterpret_cast<void*>(it.node()->object()),
           it.node()->IsWeak() ? " (weak)" : "");
  }
}

#endif



void GlobalHandles::AddObjectGroup(Object*** handles,
                                   size_t length,
                                   v8::RetainedObjectInfo* info) {
#ifdef DEBUG
  for (size_t i = 0; i < length; ++i) {
    ASSERT(!Node::FromLocation(handles[i])->is_independent());
  }
#endif
  if (length == 0) {
    if (info != NULL) info->Dispose();
    return;
  }
  object_groups_.Add(ObjectGroup::New(handles, length, info));
}


void GlobalHandles::AddImplicitReferences(HeapObject** parent,
                                          Object*** children,
                                          size_t length) {
#ifdef DEBUG
  ASSERT(!Node::FromLocation(BitCast<Object**>(parent))->is_independent());
  for (size_t i = 0; i < length; ++i) {
    ASSERT(!Node::FromLocation(children[i])->is_independent());
  }
#endif
  if (length == 0) return;
  implicit_ref_groups_.Add(ImplicitRefGroup::New(parent, children, length));
}


void GlobalHandles::RemoveObjectGroups() {
  for (int i = 0; i < object_groups_.length(); i++) {
    object_groups_.at(i)->Dispose();
  }
  object_groups_.Clear();
}


void GlobalHandles::RemoveImplicitRefGroups() {
  for (int i = 0; i < implicit_ref_groups_.length(); i++) {
    implicit_ref_groups_.at(i)->Dispose();
  }
  implicit_ref_groups_.Clear();
}


void GlobalHandles::TearDown() {
  // TODO(1428): invoke weak callbacks.
}


} }  // namespace v8::internal
