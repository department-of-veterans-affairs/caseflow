// Copyright 2007-2008 the V8 project authors. All rights reserved.
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

#include <stdlib.h>

#include "v8.h"

#include "heap.h"
#include "cctest.h"

using namespace v8;


enum Expectations {
  EXPECT_RESULT,
  EXPECT_EXCEPTION,
  EXPECT_ERROR
};


// A DeclarationContext holds a reference to a v8::Context and keeps
// track of various declaration related counters to make it easier to
// track if global declarations in the presence of interceptors behave
// the right way.
class DeclarationContext {
 public:
  DeclarationContext();

  virtual ~DeclarationContext() {
    if (is_initialized_) {
      context_->Exit();
      context_.Dispose(context_->GetIsolate());
    }
  }

  void Check(const char* source,
             int get, int set, int has,
             Expectations expectations,
             v8::Handle<Value> value = Local<Value>());

  int get_count() const { return get_count_; }
  int set_count() const { return set_count_; }
  int query_count() const { return query_count_; }

 protected:
  virtual v8::Handle<Value> Get(Local<String> key);
  virtual v8::Handle<Value> Set(Local<String> key, Local<Value> value);
  virtual v8::Handle<Integer> Query(Local<String> key);

  void InitializeIfNeeded();

  // Perform optional initialization steps on the context after it has
  // been created. Defaults to none but may be overwritten.
  virtual void PostInitializeContext(Handle<Context> context) {}

  // Get the holder for the interceptor. Default to the instance template
  // but may be overwritten.
  virtual Local<ObjectTemplate> GetHolder(Local<FunctionTemplate> function) {
    return function->InstanceTemplate();
  }

  // The handlers are called as static functions that forward
  // to the instance specific virtual methods.
  static v8::Handle<Value> HandleGet(Local<String> key,
                                     const AccessorInfo& info);
  static v8::Handle<Value> HandleSet(Local<String> key,
                                     Local<Value> value,
                                     const AccessorInfo& info);
  static v8::Handle<Integer> HandleQuery(Local<String> key,
                                         const AccessorInfo& info);

 private:
  bool is_initialized_;
  Persistent<Context> context_;

  int get_count_;
  int set_count_;
  int query_count_;

  static DeclarationContext* GetInstance(const AccessorInfo& info);
};


DeclarationContext::DeclarationContext()
    : is_initialized_(false), get_count_(0), set_count_(0), query_count_(0) {
  // Do nothing.
}


void DeclarationContext::InitializeIfNeeded() {
  if (is_initialized_) return;
  HandleScope scope;
  Local<FunctionTemplate> function = FunctionTemplate::New();
  Local<Value> data = External::New(this);
  GetHolder(function)->SetNamedPropertyHandler(&HandleGet,
                                               &HandleSet,
                                               &HandleQuery,
                                               0, 0,
                                               data);
  context_ = Context::New(0, function->InstanceTemplate(), Local<Value>());
  context_->Enter();
  is_initialized_ = true;
  PostInitializeContext(context_);
}


void DeclarationContext::Check(const char* source,
                               int get, int set, int query,
                               Expectations expectations,
                               v8::Handle<Value> value) {
  InitializeIfNeeded();
  // A retry after a GC may pollute the counts, so perform gc now
  // to avoid that.
  HEAP->CollectGarbage(v8::internal::NEW_SPACE);
  HandleScope scope;
  TryCatch catcher;
  catcher.SetVerbose(true);
  Local<Script> script = Script::Compile(String::New(source));
  if (expectations == EXPECT_ERROR) {
    CHECK(script.IsEmpty());
    return;
  }
  CHECK(!script.IsEmpty());
  Local<Value> result = script->Run();
  CHECK_EQ(get, get_count());
  CHECK_EQ(set, set_count());
  CHECK_EQ(query, query_count());
  if (expectations == EXPECT_RESULT) {
    CHECK(!catcher.HasCaught());
    if (!value.IsEmpty()) {
      CHECK_EQ(value, result);
    }
  } else {
    CHECK(expectations == EXPECT_EXCEPTION);
    CHECK(catcher.HasCaught());
    if (!value.IsEmpty()) {
      CHECK_EQ(value, catcher.Exception());
    }
  }
  HEAP->CollectAllAvailableGarbage();  // Clean slate for the next test.
}


v8::Handle<Value> DeclarationContext::HandleGet(Local<String> key,
                                                const AccessorInfo& info) {
  DeclarationContext* context = GetInstance(info);
  context->get_count_++;
  return context->Get(key);
}


v8::Handle<Value> DeclarationContext::HandleSet(Local<String> key,
                                                Local<Value> value,
                                                const AccessorInfo& info) {
  DeclarationContext* context = GetInstance(info);
  context->set_count_++;
  return context->Set(key, value);
}


v8::Handle<Integer> DeclarationContext::HandleQuery(Local<String> key,
                                                    const AccessorInfo& info) {
  DeclarationContext* context = GetInstance(info);
  context->query_count_++;
  return context->Query(key);
}


DeclarationContext* DeclarationContext::GetInstance(const AccessorInfo& info) {
  void* value = External::Cast(*info.Data())->Value();
  return static_cast<DeclarationContext*>(value);
}


v8::Handle<Value> DeclarationContext::Get(Local<String> key) {
  return v8::Handle<Value>();
}


v8::Handle<Value> DeclarationContext::Set(Local<String> key,
                                          Local<Value> value) {
  return v8::Handle<Value>();
}


v8::Handle<Integer> DeclarationContext::Query(Local<String> key) {
  return v8::Handle<Integer>();
}


// Test global declaration of a property the interceptor doesn't know
// about and doesn't handle.
TEST(Unknown) {
  HandleScope scope;

  { DeclarationContext context;
    context.Check("var x; x",
                  1,  // access
                  1,  // declaration
                  2,  // declaration + initialization
                  EXPECT_RESULT, Undefined());
  }

  { DeclarationContext context;
    context.Check("var x = 0; x",
                  1,  // access
                  2,  // declaration + initialization
                  2,  // declaration + initialization
                  EXPECT_RESULT, Number::New(0));
  }

  { DeclarationContext context;
    context.Check("function x() { }; x",
                  1,  // access
                  0,
                  0,
                  EXPECT_RESULT);
  }

  { DeclarationContext context;
    context.Check("const x; x",
                  1,  // access
                  2,  // declaration + initialization
                  1,  // declaration
                  EXPECT_RESULT, Undefined());
  }

  { DeclarationContext context;
    context.Check("const x = 0; x",
                  1,  // access
                  2,  // declaration + initialization
                  1,  // declaration
                  EXPECT_RESULT, Undefined());  // SB 0 - BUG 1213579
  }
}



class PresentPropertyContext: public DeclarationContext {
 protected:
  virtual v8::Handle<Integer> Query(Local<String> key) {
    return Integer::New(v8::None);
  }
};



TEST(Present) {
  HandleScope scope;

  { PresentPropertyContext context;
    context.Check("var x; x",
                  1,  // access
                  0,
                  2,  // declaration + initialization
                  EXPECT_EXCEPTION);  // x is not defined!
  }

  { PresentPropertyContext context;
    context.Check("var x = 0; x",
                  1,  // access
                  1,  // initialization
                  2,  // declaration + initialization
                  EXPECT_RESULT, Number::New(0));
  }

  { PresentPropertyContext context;
    context.Check("function x() { }; x",
                  1,  // access
                  0,
                  0,
                  EXPECT_RESULT);
  }

  { PresentPropertyContext context;
    context.Check("const x; x",
                  1,  // access
                  1,  // initialization
                  1,  // (re-)declaration
                  EXPECT_RESULT, Undefined());
  }

  { PresentPropertyContext context;
    context.Check("const x = 0; x",
                  1,  // access
                  1,  // initialization
                  1,  // (re-)declaration
                  EXPECT_RESULT, Number::New(0));
  }
}



class AbsentPropertyContext: public DeclarationContext {
 protected:
  virtual v8::Handle<Integer> Query(Local<String> key) {
    return v8::Handle<Integer>();
  }
};


TEST(Absent) {
  HandleScope scope;

  { AbsentPropertyContext context;
    context.Check("var x; x",
                  1,  // access
                  1,  // declaration
                  2,  // declaration + initialization
                  EXPECT_RESULT, Undefined());
  }

  { AbsentPropertyContext context;
    context.Check("var x = 0; x",
                  1,  // access
                  2,  // declaration + initialization
                  2,  // declaration + initialization
                  EXPECT_RESULT, Number::New(0));
  }

  { AbsentPropertyContext context;
    context.Check("function x() { }; x",
                  1,  // access
                  0,
                  0,
                  EXPECT_RESULT);
  }

  { AbsentPropertyContext context;
    context.Check("const x; x",
                  1,  // access
                  2,  // declaration + initialization
                  1,  // declaration
                  EXPECT_RESULT, Undefined());
  }

  { AbsentPropertyContext context;
    context.Check("const x = 0; x",
                  1,  // access
                  2,  // declaration + initialization
                  1,  // declaration
                  EXPECT_RESULT, Undefined());  // SB 0 - BUG 1213579
  }

  { AbsentPropertyContext context;
    context.Check("if (false) { var x = 0 }; x",
                  1,  // access
                  1,  // declaration
                  1,  // declaration + initialization
                  EXPECT_RESULT, Undefined());
  }
}



class AppearingPropertyContext: public DeclarationContext {
 public:
  enum State {
    DECLARE,
    INITIALIZE_IF_ASSIGN,
    UNKNOWN
  };

  AppearingPropertyContext() : state_(DECLARE) { }

 protected:
  virtual v8::Handle<Integer> Query(Local<String> key) {
    switch (state_) {
      case DECLARE:
        // Force declaration by returning that the
        // property is absent.
        state_ = INITIALIZE_IF_ASSIGN;
        return Handle<Integer>();
      case INITIALIZE_IF_ASSIGN:
        // Return that the property is present so we only get the
        // setter called when initializing with a value.
        state_ = UNKNOWN;
        return Integer::New(v8::None);
      default:
        CHECK(state_ == UNKNOWN);
        break;
    }
    // Do the lookup in the object.
    return v8::Handle<Integer>();
  }

 private:
  State state_;
};


TEST(Appearing) {
  HandleScope scope;

  { AppearingPropertyContext context;
    context.Check("var x; x",
                  1,  // access
                  1,  // declaration
                  2,  // declaration + initialization
                  EXPECT_RESULT, Undefined());
  }

  { AppearingPropertyContext context;
    context.Check("var x = 0; x",
                  1,  // access
                  2,  // declaration + initialization
                  2,  // declaration + initialization
                  EXPECT_RESULT, Number::New(0));
  }

  { AppearingPropertyContext context;
    context.Check("function x() { }; x",
                  1,  // access
                  0,
                  0,
                  EXPECT_RESULT);
  }

  { AppearingPropertyContext context;
    context.Check("const x; x",
                  1,  // access
                  2,  // declaration + initialization
                  1,  // declaration
                  EXPECT_RESULT, Undefined());
  }

  { AppearingPropertyContext context;
    context.Check("const x = 0; x",
                  1,  // access
                  2,  // declaration + initialization
                  1,  // declaration
                  EXPECT_RESULT, Undefined());
                  // Result is undefined because declaration succeeded but
                  // initialization to 0 failed (due to context behavior).
  }
}



class ReappearingPropertyContext: public DeclarationContext {
 public:
  enum State {
    DECLARE,
    DONT_DECLARE,
    INITIALIZE,
    UNKNOWN
  };

  ReappearingPropertyContext() : state_(DECLARE) { }

 protected:
  virtual v8::Handle<Integer> Query(Local<String> key) {
    switch (state_) {
      case DECLARE:
        // Force the first declaration by returning that
        // the property is absent.
        state_ = DONT_DECLARE;
        return Handle<Integer>();
      case DONT_DECLARE:
        // Ignore the second declaration by returning
        // that the property is already there.
        state_ = INITIALIZE;
        return Integer::New(v8::None);
      case INITIALIZE:
        // Force an initialization by returning that
        // the property is absent. This will make sure
        // that the setter is called and it will not
        // lead to redeclaration conflicts (yet).
        state_ = UNKNOWN;
        return Handle<Integer>();
      default:
        CHECK(state_ == UNKNOWN);
        break;
    }
    // Do the lookup in the object.
    return Handle<Integer>();
  }

 private:
  State state_;
};


TEST(Reappearing) {
  HandleScope scope;

  { ReappearingPropertyContext context;
    context.Check("const x; var x = 0",
                  0,
                  3,  // const declaration+initialization, var initialization
                  3,  // 2 x declaration + var initialization
                  EXPECT_RESULT, Undefined());
  }
}



class ExistsInPrototypeContext: public DeclarationContext {
 protected:
  virtual v8::Handle<Integer> Query(Local<String> key) {
    // Let it seem that the property exists in the prototype object.
    return Integer::New(v8::None);
  }

  // Use the prototype as the holder for the interceptors.
  virtual Local<ObjectTemplate> GetHolder(Local<FunctionTemplate> function) {
    return function->PrototypeTemplate();
  }
};


TEST(ExistsInPrototype) {
  i::FLAG_es52_globals = true;
  HandleScope scope;

  // Sanity check to make sure that the holder of the interceptor
  // really is the prototype object.
  { ExistsInPrototypeContext context;
    context.Check("this.x = 87; this.x",
                  0,
                  0,
                  0,
                  EXPECT_RESULT, Number::New(87));
  }

  { ExistsInPrototypeContext context;
    context.Check("var x; x",
                  0,
                  0,
                  0,
                  EXPECT_RESULT, Undefined());
  }

  { ExistsInPrototypeContext context;
    context.Check("var x = 0; x",
                  0,
                  0,
                  0,
                  EXPECT_RESULT, Number::New(0));
  }

  { ExistsInPrototypeContext context;
    context.Check("const x; x",
                  0,
                  0,
                  0,
                  EXPECT_RESULT, Undefined());
  }

  { ExistsInPrototypeContext context;
    context.Check("const x = 0; x",
                  0,
                  0,
                  0,
                  EXPECT_RESULT, Number::New(0));
  }
}



class AbsentInPrototypeContext: public DeclarationContext {
 protected:
  virtual v8::Handle<Integer> Query(Local<String> key) {
    // Let it seem that the property is absent in the prototype object.
    return Handle<Integer>();
  }

  // Use the prototype as the holder for the interceptors.
  virtual Local<ObjectTemplate> GetHolder(Local<FunctionTemplate> function) {
    return function->PrototypeTemplate();
  }
};


TEST(AbsentInPrototype) {
  i::FLAG_es52_globals = true;
  HandleScope scope;

  { AbsentInPrototypeContext context;
    context.Check("if (false) { var x = 0; }; x",
                  0,
                  0,
                  0,
                  EXPECT_RESULT, Undefined());
  }
}



class ExistsInHiddenPrototypeContext: public DeclarationContext {
 public:
  ExistsInHiddenPrototypeContext() {
    hidden_proto_ = FunctionTemplate::New();
    hidden_proto_->SetHiddenPrototype(true);
  }

 protected:
  virtual v8::Handle<Integer> Query(Local<String> key) {
    // Let it seem that the property exists in the hidden prototype object.
    return Integer::New(v8::None);
  }

  // Install the hidden prototype after the global object has been created.
  virtual void PostInitializeContext(Handle<Context> context) {
    Local<Object> global_object = context->Global();
    Local<Object> hidden_proto = hidden_proto_->GetFunction()->NewInstance();
    context->DetachGlobal();
    context->Global()->SetPrototype(hidden_proto);
    context->ReattachGlobal(global_object);
  }

  // Use the hidden prototype as the holder for the interceptors.
  virtual Local<ObjectTemplate> GetHolder(Local<FunctionTemplate> function) {
    return hidden_proto_->InstanceTemplate();
  }

 private:
  Local<FunctionTemplate> hidden_proto_;
};


TEST(ExistsInHiddenPrototype) {
  i::FLAG_es52_globals = true;
  HandleScope scope;

  { ExistsInHiddenPrototypeContext context;
    context.Check("var x; x",
                  1,  // access
                  0,
                  2,  // declaration + initialization
                  EXPECT_EXCEPTION);  // x is not defined!
  }

  { ExistsInHiddenPrototypeContext context;
    context.Check("var x = 0; x",
                  1,  // access
                  1,  // initialization
                  2,  // declaration + initialization
                  EXPECT_RESULT, Number::New(0));
  }

  { ExistsInHiddenPrototypeContext context;
    context.Check("function x() { }; x",
                  0,
                  0,
                  0,
                  EXPECT_RESULT);
  }

  // TODO(mstarzinger): The semantics of global const is vague.
  { ExistsInHiddenPrototypeContext context;
    context.Check("const x; x",
                  0,
                  0,
                  1,  // (re-)declaration
                  EXPECT_RESULT, Undefined());
  }

  // TODO(mstarzinger): The semantics of global const is vague.
  { ExistsInHiddenPrototypeContext context;
    context.Check("const x = 0; x",
                  0,
                  0,
                  1,  // (re-)declaration
                  EXPECT_RESULT, Number::New(0));
  }
}



class SimpleContext {
 public:
  SimpleContext() {
    context_ = Context::New(0);
    context_->Enter();
  }

  virtual ~SimpleContext() {
    context_->Exit();
    context_.Dispose(context_->GetIsolate());
  }

  void Check(const char* source,
             Expectations expectations,
             v8::Handle<Value> value = Local<Value>()) {
    HandleScope scope;
    TryCatch catcher;
    catcher.SetVerbose(true);
    Local<Script> script = Script::Compile(String::New(source));
    if (expectations == EXPECT_ERROR) {
      CHECK(script.IsEmpty());
      return;
    }
    CHECK(!script.IsEmpty());
    Local<Value> result = script->Run();
    if (expectations == EXPECT_RESULT) {
      CHECK(!catcher.HasCaught());
      if (!value.IsEmpty()) {
        CHECK_EQ(value, result);
      }
    } else {
      CHECK(expectations == EXPECT_EXCEPTION);
      CHECK(catcher.HasCaught());
      if (!value.IsEmpty()) {
        CHECK_EQ(value, catcher.Exception());
      }
    }
  }

 private:
  Persistent<Context> context_;
};


TEST(CrossScriptReferences) {
  HandleScope scope;

  { SimpleContext context;
    context.Check("var x = 1; x",
                  EXPECT_RESULT, Number::New(1));
    context.Check("var x = 2; x",
                  EXPECT_RESULT, Number::New(2));
    context.Check("const x = 3; x",
                  EXPECT_RESULT, Number::New(3));
    context.Check("const x = 4; x",
                  EXPECT_RESULT, Number::New(4));
    context.Check("x = 5; x",
                  EXPECT_RESULT, Number::New(5));
    context.Check("var x = 6; x",
                  EXPECT_RESULT, Number::New(6));
    context.Check("this.x",
                  EXPECT_RESULT, Number::New(6));
    context.Check("function x() { return 7 }; x()",
                  EXPECT_RESULT, Number::New(7));
  }

  { SimpleContext context;
    context.Check("const x = 1; x",
                  EXPECT_RESULT, Number::New(1));
    context.Check("var x = 2; x",  // assignment ignored
                  EXPECT_RESULT, Number::New(1));
    context.Check("const x = 3; x",
                  EXPECT_RESULT, Number::New(1));
    context.Check("x = 4; x",  // assignment ignored
                  EXPECT_RESULT, Number::New(1));
    context.Check("var x = 5; x",  // assignment ignored
                  EXPECT_RESULT, Number::New(1));
    context.Check("this.x",
                  EXPECT_RESULT, Number::New(1));
    context.Check("function x() { return 7 }; x",
                  EXPECT_EXCEPTION);
  }
}


TEST(CrossScriptReferencesHarmony) {
  i::FLAG_use_strict = true;
  i::FLAG_harmony_scoping = true;
  i::FLAG_harmony_modules = true;

  HandleScope scope;

  const char* decs[] = {
    "var x = 1; x", "x", "this.x",
    "function x() { return 1 }; x()", "x()", "this.x()",
    "let x = 1; x", "x", "this.x",
    "const x = 1; x", "x", "this.x",
    "module x { export let a = 1 }; x.a", "x.a", "this.x.a",
    NULL
  };

  for (int i = 0; decs[i] != NULL; i += 3) {
    SimpleContext context;
    context.Check(decs[i], EXPECT_RESULT, Number::New(1));
    context.Check(decs[i+1], EXPECT_RESULT, Number::New(1));
    // TODO(rossberg): The current ES6 draft spec does not reflect lexical
    // bindings on the global object. However, this will probably change, in
    // which case we reactivate the following test.
    if (i/3 < 2) context.Check(decs[i+2], EXPECT_RESULT, Number::New(1));
  }
}


TEST(CrossScriptConflicts) {
  i::FLAG_use_strict = true;
  i::FLAG_harmony_scoping = true;
  i::FLAG_harmony_modules = true;

  HandleScope scope;

  const char* firsts[] = {
    "var x = 1; x",
    "function x() { return 1 }; x()",
    "let x = 1; x",
    "const x = 1; x",
    "module x { export let a = 1 }; x.a",
    NULL
  };
  const char* seconds[] = {
    "var x = 2; x",
    "function x() { return 2 }; x()",
    "let x = 2; x",
    "const x = 2; x",
    "module x { export let a = 2 }; x.a",
    NULL
  };

  for (int i = 0; firsts[i] != NULL; ++i) {
    for (int j = 0; seconds[j] != NULL; ++j) {
      SimpleContext context;
      context.Check(firsts[i], EXPECT_RESULT, Number::New(1));
      // TODO(rossberg): All tests should actually be errors in Harmony,
      // but we currently do not detect the cases where the first declaration
      // is not lexical.
      context.Check(seconds[j],
                    i < 2 ? EXPECT_RESULT : EXPECT_ERROR, Number::New(2));
    }
  }
}
