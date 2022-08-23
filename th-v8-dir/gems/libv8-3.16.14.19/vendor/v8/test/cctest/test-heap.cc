// Copyright 2012 the V8 project authors. All rights reserved.

#include <stdlib.h>

#include "v8.h"

#include "compilation-cache.h"
#include "execution.h"
#include "factory.h"
#include "macro-assembler.h"
#include "global-handles.h"
#include "stub-cache.h"
#include "cctest.h"

using namespace v8::internal;

static v8::Persistent<v8::Context> env;

static void InitializeVM() {
  if (env.IsEmpty()) env = v8::Context::New();
  v8::HandleScope scope;
  env->Enter();
}


// Go through all incremental marking steps in one swoop.
static void SimulateIncrementalMarking() {
  IncrementalMarking* marking = HEAP->incremental_marking();
  CHECK(marking->IsMarking() || marking->IsStopped());
  if (marking->IsStopped()) {
    marking->Start();
  }
  CHECK(marking->IsMarking());
  while (!marking->IsComplete()) {
    marking->Step(MB, IncrementalMarking::NO_GC_VIA_STACK_GUARD);
  }
  CHECK(marking->IsComplete());
}


static void CheckMap(Map* map, int type, int instance_size) {
  CHECK(map->IsHeapObject());
#ifdef DEBUG
  CHECK(HEAP->Contains(map));
#endif
  CHECK_EQ(HEAP->meta_map(), map->map());
  CHECK_EQ(type, map->instance_type());
  CHECK_EQ(instance_size, map->instance_size());
}


TEST(HeapMaps) {
  InitializeVM();
  CheckMap(HEAP->meta_map(), MAP_TYPE, Map::kSize);
  CheckMap(HEAP->heap_number_map(), HEAP_NUMBER_TYPE, HeapNumber::kSize);
  CheckMap(HEAP->fixed_array_map(), FIXED_ARRAY_TYPE, kVariableSizeSentinel);
  CheckMap(HEAP->string_map(), STRING_TYPE, kVariableSizeSentinel);
}


static void CheckOddball(Object* obj, const char* string) {
  CHECK(obj->IsOddball());
  bool exc;
  Object* print_string = *Execution::ToString(Handle<Object>(obj), &exc);
  CHECK(String::cast(print_string)->IsUtf8EqualTo(CStrVector(string)));
}


static void CheckSmi(int value, const char* string) {
  bool exc;
  Object* print_string =
      *Execution::ToString(Handle<Object>(Smi::FromInt(value)), &exc);
  CHECK(String::cast(print_string)->IsUtf8EqualTo(CStrVector(string)));
}


static void CheckNumber(double value, const char* string) {
  Object* obj = HEAP->NumberFromDouble(value)->ToObjectChecked();
  CHECK(obj->IsNumber());
  bool exc;
  Object* print_string = *Execution::ToString(Handle<Object>(obj), &exc);
  CHECK(String::cast(print_string)->IsUtf8EqualTo(CStrVector(string)));
}


static void CheckFindCodeObject() {
  // Test FindCodeObject
#define __ assm.

  Assembler assm(Isolate::Current(), NULL, 0);

  __ nop();  // supported on all architectures

  CodeDesc desc;
  assm.GetCode(&desc);
  Object* code = HEAP->CreateCode(
      desc,
      Code::ComputeFlags(Code::STUB),
      Handle<Object>(HEAP->undefined_value()))->ToObjectChecked();
  CHECK(code->IsCode());

  HeapObject* obj = HeapObject::cast(code);
  Address obj_addr = obj->address();

  for (int i = 0; i < obj->Size(); i += kPointerSize) {
    Object* found = HEAP->FindCodeObject(obj_addr + i);
    CHECK_EQ(code, found);
  }

  Object* copy = HEAP->CreateCode(
      desc,
      Code::ComputeFlags(Code::STUB),
      Handle<Object>(HEAP->undefined_value()))->ToObjectChecked();
  CHECK(copy->IsCode());
  HeapObject* obj_copy = HeapObject::cast(copy);
  Object* not_right = HEAP->FindCodeObject(obj_copy->address() +
                                           obj_copy->Size() / 2);
  CHECK(not_right != code);
}


TEST(HeapObjects) {
  InitializeVM();

  v8::HandleScope sc;
  Object* value = HEAP->NumberFromDouble(1.000123)->ToObjectChecked();
  CHECK(value->IsHeapNumber());
  CHECK(value->IsNumber());
  CHECK_EQ(1.000123, value->Number());

  value = HEAP->NumberFromDouble(1.0)->ToObjectChecked();
  CHECK(value->IsSmi());
  CHECK(value->IsNumber());
  CHECK_EQ(1.0, value->Number());

  value = HEAP->NumberFromInt32(1024)->ToObjectChecked();
  CHECK(value->IsSmi());
  CHECK(value->IsNumber());
  CHECK_EQ(1024.0, value->Number());

  value = HEAP->NumberFromInt32(Smi::kMinValue)->ToObjectChecked();
  CHECK(value->IsSmi());
  CHECK(value->IsNumber());
  CHECK_EQ(Smi::kMinValue, Smi::cast(value)->value());

  value = HEAP->NumberFromInt32(Smi::kMaxValue)->ToObjectChecked();
  CHECK(value->IsSmi());
  CHECK(value->IsNumber());
  CHECK_EQ(Smi::kMaxValue, Smi::cast(value)->value());

#ifndef V8_TARGET_ARCH_X64
  // TODO(lrn): We need a NumberFromIntptr function in order to test this.
  value = HEAP->NumberFromInt32(Smi::kMinValue - 1)->ToObjectChecked();
  CHECK(value->IsHeapNumber());
  CHECK(value->IsNumber());
  CHECK_EQ(static_cast<double>(Smi::kMinValue - 1), value->Number());
#endif

  MaybeObject* maybe_value =
      HEAP->NumberFromUint32(static_cast<uint32_t>(Smi::kMaxValue) + 1);
  value = maybe_value->ToObjectChecked();
  CHECK(value->IsHeapNumber());
  CHECK(value->IsNumber());
  CHECK_EQ(static_cast<double>(static_cast<uint32_t>(Smi::kMaxValue) + 1),
           value->Number());

  maybe_value = HEAP->NumberFromUint32(static_cast<uint32_t>(1) << 31);
  value = maybe_value->ToObjectChecked();
  CHECK(value->IsHeapNumber());
  CHECK(value->IsNumber());
  CHECK_EQ(static_cast<double>(static_cast<uint32_t>(1) << 31),
           value->Number());

  // nan oddball checks
  CHECK(HEAP->nan_value()->IsNumber());
  CHECK(isnan(HEAP->nan_value()->Number()));

  Handle<String> s = FACTORY->NewStringFromAscii(CStrVector("fisk hest "));
  CHECK(s->IsString());
  CHECK_EQ(10, s->length());

  String* object_symbol = String::cast(HEAP->Object_symbol());
  CHECK(
      Isolate::Current()->context()->global_object()->HasLocalProperty(
          object_symbol));

  // Check ToString for oddballs
  CheckOddball(HEAP->true_value(), "true");
  CheckOddball(HEAP->false_value(), "false");
  CheckOddball(HEAP->null_value(), "null");
  CheckOddball(HEAP->undefined_value(), "undefined");

  // Check ToString for Smis
  CheckSmi(0, "0");
  CheckSmi(42, "42");
  CheckSmi(-42, "-42");

  // Check ToString for Numbers
  CheckNumber(1.1, "1.1");

  CheckFindCodeObject();
}


TEST(Tagging) {
  InitializeVM();
  int request = 24;
  CHECK_EQ(request, static_cast<int>(OBJECT_POINTER_ALIGN(request)));
  CHECK(Smi::FromInt(42)->IsSmi());
  CHECK(Failure::RetryAfterGC(NEW_SPACE)->IsFailure());
  CHECK_EQ(NEW_SPACE,
           Failure::RetryAfterGC(NEW_SPACE)->allocation_space());
  CHECK_EQ(OLD_POINTER_SPACE,
           Failure::RetryAfterGC(OLD_POINTER_SPACE)->allocation_space());
  CHECK(Failure::Exception()->IsFailure());
  CHECK(Smi::FromInt(Smi::kMinValue)->IsSmi());
  CHECK(Smi::FromInt(Smi::kMaxValue)->IsSmi());
}


TEST(GarbageCollection) {
  InitializeVM();

  v8::HandleScope sc;
  // Check GC.
  HEAP->CollectGarbage(NEW_SPACE);

  Handle<String> name = FACTORY->LookupUtf8Symbol("theFunction");
  Handle<String> prop_name = FACTORY->LookupUtf8Symbol("theSlot");
  Handle<String> prop_namex = FACTORY->LookupUtf8Symbol("theSlotx");
  Handle<String> obj_name = FACTORY->LookupUtf8Symbol("theObject");

  {
    v8::HandleScope inner_scope;
    // Allocate a function and keep it in global object's property.
    Handle<JSFunction> function =
        FACTORY->NewFunction(name, FACTORY->undefined_value());
    Handle<Map> initial_map =
        FACTORY->NewMap(JS_OBJECT_TYPE, JSObject::kHeaderSize);
    function->set_initial_map(*initial_map);
    Isolate::Current()->context()->global_object()->SetProperty(
        *name, *function, NONE, kNonStrictMode)->ToObjectChecked();
    // Allocate an object.  Unrooted after leaving the scope.
    Handle<JSObject> obj = FACTORY->NewJSObject(function);
    obj->SetProperty(
        *prop_name, Smi::FromInt(23), NONE, kNonStrictMode)->ToObjectChecked();
    obj->SetProperty(
        *prop_namex, Smi::FromInt(24), NONE, kNonStrictMode)->ToObjectChecked();

    CHECK_EQ(Smi::FromInt(23), obj->GetProperty(*prop_name));
    CHECK_EQ(Smi::FromInt(24), obj->GetProperty(*prop_namex));
  }

  HEAP->CollectGarbage(NEW_SPACE);

  // Function should be alive.
  CHECK(Isolate::Current()->context()->global_object()->
        HasLocalProperty(*name));
  // Check function is retained.
  Object* func_value = Isolate::Current()->context()->global_object()->
      GetProperty(*name)->ToObjectChecked();
  CHECK(func_value->IsJSFunction());
  Handle<JSFunction> function(JSFunction::cast(func_value));

  {
    HandleScope inner_scope;
    // Allocate another object, make it reachable from global.
    Handle<JSObject> obj = FACTORY->NewJSObject(function);
    Isolate::Current()->context()->global_object()->SetProperty(
        *obj_name, *obj, NONE, kNonStrictMode)->ToObjectChecked();
    obj->SetProperty(
        *prop_name, Smi::FromInt(23), NONE, kNonStrictMode)->ToObjectChecked();
  }

  // After gc, it should survive.
  HEAP->CollectGarbage(NEW_SPACE);

  CHECK(Isolate::Current()->context()->global_object()->
        HasLocalProperty(*obj_name));
  CHECK(Isolate::Current()->context()->global_object()->
        GetProperty(*obj_name)->ToObjectChecked()->IsJSObject());
  Object* obj = Isolate::Current()->context()->global_object()->
      GetProperty(*obj_name)->ToObjectChecked();
  JSObject* js_obj = JSObject::cast(obj);
  CHECK_EQ(Smi::FromInt(23), js_obj->GetProperty(*prop_name));
}


static void VerifyStringAllocation(const char* string) {
  v8::HandleScope scope;
  Handle<String> s = FACTORY->NewStringFromUtf8(CStrVector(string));
  CHECK_EQ(StrLength(string), s->length());
  for (int index = 0; index < s->length(); index++) {
    CHECK_EQ(static_cast<uint16_t>(string[index]), s->Get(index));
  }
}


TEST(String) {
  InitializeVM();

  VerifyStringAllocation("a");
  VerifyStringAllocation("ab");
  VerifyStringAllocation("abc");
  VerifyStringAllocation("abcd");
  VerifyStringAllocation("fiskerdrengen er paa havet");
}


TEST(LocalHandles) {
  InitializeVM();

  v8::HandleScope scope;
  const char* name = "Kasper the spunky";
  Handle<String> string = FACTORY->NewStringFromAscii(CStrVector(name));
  CHECK_EQ(StrLength(name), string->length());
}


TEST(GlobalHandles) {
  InitializeVM();
  GlobalHandles* global_handles = Isolate::Current()->global_handles();

  Handle<Object> h1;
  Handle<Object> h2;
  Handle<Object> h3;
  Handle<Object> h4;

  {
    HandleScope scope;

    Handle<Object> i = FACTORY->NewStringFromAscii(CStrVector("fisk"));
    Handle<Object> u = FACTORY->NewNumber(1.12344);

    h1 = global_handles->Create(*i);
    h2 = global_handles->Create(*u);
    h3 = global_handles->Create(*i);
    h4 = global_handles->Create(*u);
  }

  // after gc, it should survive
  HEAP->CollectGarbage(NEW_SPACE);

  CHECK((*h1)->IsString());
  CHECK((*h2)->IsHeapNumber());
  CHECK((*h3)->IsString());
  CHECK((*h4)->IsHeapNumber());

  CHECK_EQ(*h3, *h1);
  global_handles->Destroy(h1.location());
  global_handles->Destroy(h3.location());

  CHECK_EQ(*h4, *h2);
  global_handles->Destroy(h2.location());
  global_handles->Destroy(h4.location());
}


static bool WeakPointerCleared = false;

static void TestWeakGlobalHandleCallback(v8::Isolate* isolate,
                                         v8::Persistent<v8::Value> handle,
                                         void* id) {
  if (1234 == reinterpret_cast<intptr_t>(id)) WeakPointerCleared = true;
  handle.Dispose(isolate);
}


TEST(WeakGlobalHandlesScavenge) {
  InitializeVM();
  GlobalHandles* global_handles = Isolate::Current()->global_handles();

  WeakPointerCleared = false;

  Handle<Object> h1;
  Handle<Object> h2;

  {
    HandleScope scope;

    Handle<Object> i = FACTORY->NewStringFromAscii(CStrVector("fisk"));
    Handle<Object> u = FACTORY->NewNumber(1.12344);

    h1 = global_handles->Create(*i);
    h2 = global_handles->Create(*u);
  }

  global_handles->MakeWeak(h2.location(),
                           reinterpret_cast<void*>(1234),
                           NULL,
                           &TestWeakGlobalHandleCallback);

  // Scavenge treats weak pointers as normal roots.
  HEAP->PerformScavenge();

  CHECK((*h1)->IsString());
  CHECK((*h2)->IsHeapNumber());

  CHECK(!WeakPointerCleared);
  CHECK(!global_handles->IsNearDeath(h2.location()));
  CHECK(!global_handles->IsNearDeath(h1.location()));

  global_handles->Destroy(h1.location());
  global_handles->Destroy(h2.location());
}


TEST(WeakGlobalHandlesMark) {
  InitializeVM();
  GlobalHandles* global_handles = Isolate::Current()->global_handles();

  WeakPointerCleared = false;

  Handle<Object> h1;
  Handle<Object> h2;

  {
    HandleScope scope;

    Handle<Object> i = FACTORY->NewStringFromAscii(CStrVector("fisk"));
    Handle<Object> u = FACTORY->NewNumber(1.12344);

    h1 = global_handles->Create(*i);
    h2 = global_handles->Create(*u);
  }

  // Make sure the objects are promoted.
  HEAP->CollectGarbage(OLD_POINTER_SPACE);
  HEAP->CollectGarbage(NEW_SPACE);
  CHECK(!HEAP->InNewSpace(*h1) && !HEAP->InNewSpace(*h2));

  global_handles->MakeWeak(h2.location(),
                           reinterpret_cast<void*>(1234),
                           NULL,
                           &TestWeakGlobalHandleCallback);
  CHECK(!GlobalHandles::IsNearDeath(h1.location()));
  CHECK(!GlobalHandles::IsNearDeath(h2.location()));

  // Incremental marking potentially marked handles before they turned weak.
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);

  CHECK((*h1)->IsString());

  CHECK(WeakPointerCleared);
  CHECK(!GlobalHandles::IsNearDeath(h1.location()));

  global_handles->Destroy(h1.location());
}


TEST(DeleteWeakGlobalHandle) {
  InitializeVM();
  GlobalHandles* global_handles = Isolate::Current()->global_handles();

  WeakPointerCleared = false;

  Handle<Object> h;

  {
    HandleScope scope;

    Handle<Object> i = FACTORY->NewStringFromAscii(CStrVector("fisk"));
    h = global_handles->Create(*i);
  }

  global_handles->MakeWeak(h.location(),
                           reinterpret_cast<void*>(1234),
                           NULL,
                           &TestWeakGlobalHandleCallback);

  // Scanvenge does not recognize weak reference.
  HEAP->PerformScavenge();

  CHECK(!WeakPointerCleared);

  // Mark-compact treats weak reference properly.
  HEAP->CollectGarbage(OLD_POINTER_SPACE);

  CHECK(WeakPointerCleared);
}


static const char* not_so_random_string_table[] = {
  "abstract",
  "boolean",
  "break",
  "byte",
  "case",
  "catch",
  "char",
  "class",
  "const",
  "continue",
  "debugger",
  "default",
  "delete",
  "do",
  "double",
  "else",
  "enum",
  "export",
  "extends",
  "false",
  "final",
  "finally",
  "float",
  "for",
  "function",
  "goto",
  "if",
  "implements",
  "import",
  "in",
  "instanceof",
  "int",
  "interface",
  "long",
  "native",
  "new",
  "null",
  "package",
  "private",
  "protected",
  "public",
  "return",
  "short",
  "static",
  "super",
  "switch",
  "synchronized",
  "this",
  "throw",
  "throws",
  "transient",
  "true",
  "try",
  "typeof",
  "var",
  "void",
  "volatile",
  "while",
  "with",
  0
};


static void CheckSymbols(const char** strings) {
  for (const char* string = *strings; *strings != 0; string = *strings++) {
    Object* a;
    MaybeObject* maybe_a = HEAP->LookupUtf8Symbol(string);
    // LookupUtf8Symbol may return a failure if a GC is needed.
    if (!maybe_a->ToObject(&a)) continue;
    CHECK(a->IsSymbol());
    Object* b;
    MaybeObject* maybe_b = HEAP->LookupUtf8Symbol(string);
    if (!maybe_b->ToObject(&b)) continue;
    CHECK_EQ(b, a);
    CHECK(String::cast(b)->IsUtf8EqualTo(CStrVector(string)));
  }
}


TEST(SymbolTable) {
  InitializeVM();

  CheckSymbols(not_so_random_string_table);
  CheckSymbols(not_so_random_string_table);
}


TEST(FunctionAllocation) {
  InitializeVM();

  v8::HandleScope sc;
  Handle<String> name = FACTORY->LookupUtf8Symbol("theFunction");
  Handle<JSFunction> function =
      FACTORY->NewFunction(name, FACTORY->undefined_value());
  Handle<Map> initial_map =
      FACTORY->NewMap(JS_OBJECT_TYPE, JSObject::kHeaderSize);
  function->set_initial_map(*initial_map);

  Handle<String> prop_name = FACTORY->LookupUtf8Symbol("theSlot");
  Handle<JSObject> obj = FACTORY->NewJSObject(function);
  obj->SetProperty(
      *prop_name, Smi::FromInt(23), NONE, kNonStrictMode)->ToObjectChecked();
  CHECK_EQ(Smi::FromInt(23), obj->GetProperty(*prop_name));
  // Check that we can add properties to function objects.
  function->SetProperty(
      *prop_name, Smi::FromInt(24), NONE, kNonStrictMode)->ToObjectChecked();
  CHECK_EQ(Smi::FromInt(24), function->GetProperty(*prop_name));
}


TEST(ObjectProperties) {
  InitializeVM();

  v8::HandleScope sc;
  String* object_symbol = String::cast(HEAP->Object_symbol());
  Object* raw_object = Isolate::Current()->context()->global_object()->
      GetProperty(object_symbol)->ToObjectChecked();
  JSFunction* object_function = JSFunction::cast(raw_object);
  Handle<JSFunction> constructor(object_function);
  Handle<JSObject> obj = FACTORY->NewJSObject(constructor);
  Handle<String> first = FACTORY->LookupUtf8Symbol("first");
  Handle<String> second = FACTORY->LookupUtf8Symbol("second");

  // check for empty
  CHECK(!obj->HasLocalProperty(*first));

  // add first
  obj->SetProperty(
      *first, Smi::FromInt(1), NONE, kNonStrictMode)->ToObjectChecked();
  CHECK(obj->HasLocalProperty(*first));

  // delete first
  CHECK(obj->DeleteProperty(*first, JSObject::NORMAL_DELETION));
  CHECK(!obj->HasLocalProperty(*first));

  // add first and then second
  obj->SetProperty(
      *first, Smi::FromInt(1), NONE, kNonStrictMode)->ToObjectChecked();
  obj->SetProperty(
      *second, Smi::FromInt(2), NONE, kNonStrictMode)->ToObjectChecked();
  CHECK(obj->HasLocalProperty(*first));
  CHECK(obj->HasLocalProperty(*second));

  // delete first and then second
  CHECK(obj->DeleteProperty(*first, JSObject::NORMAL_DELETION));
  CHECK(obj->HasLocalProperty(*second));
  CHECK(obj->DeleteProperty(*second, JSObject::NORMAL_DELETION));
  CHECK(!obj->HasLocalProperty(*first));
  CHECK(!obj->HasLocalProperty(*second));

  // add first and then second
  obj->SetProperty(
      *first, Smi::FromInt(1), NONE, kNonStrictMode)->ToObjectChecked();
  obj->SetProperty(
      *second, Smi::FromInt(2), NONE, kNonStrictMode)->ToObjectChecked();
  CHECK(obj->HasLocalProperty(*first));
  CHECK(obj->HasLocalProperty(*second));

  // delete second and then first
  CHECK(obj->DeleteProperty(*second, JSObject::NORMAL_DELETION));
  CHECK(obj->HasLocalProperty(*first));
  CHECK(obj->DeleteProperty(*first, JSObject::NORMAL_DELETION));
  CHECK(!obj->HasLocalProperty(*first));
  CHECK(!obj->HasLocalProperty(*second));

  // check string and symbol match
  const char* string1 = "fisk";
  Handle<String> s1 = FACTORY->NewStringFromAscii(CStrVector(string1));
  obj->SetProperty(
      *s1, Smi::FromInt(1), NONE, kNonStrictMode)->ToObjectChecked();
  Handle<String> s1_symbol = FACTORY->LookupUtf8Symbol(string1);
  CHECK(obj->HasLocalProperty(*s1_symbol));

  // check symbol and string match
  const char* string2 = "fugl";
  Handle<String> s2_symbol = FACTORY->LookupUtf8Symbol(string2);
  obj->SetProperty(
      *s2_symbol, Smi::FromInt(1), NONE, kNonStrictMode)->ToObjectChecked();
  Handle<String> s2 = FACTORY->NewStringFromAscii(CStrVector(string2));
  CHECK(obj->HasLocalProperty(*s2));
}


TEST(JSObjectMaps) {
  InitializeVM();

  v8::HandleScope sc;
  Handle<String> name = FACTORY->LookupUtf8Symbol("theFunction");
  Handle<JSFunction> function =
      FACTORY->NewFunction(name, FACTORY->undefined_value());
  Handle<Map> initial_map =
      FACTORY->NewMap(JS_OBJECT_TYPE, JSObject::kHeaderSize);
  function->set_initial_map(*initial_map);

  Handle<String> prop_name = FACTORY->LookupUtf8Symbol("theSlot");
  Handle<JSObject> obj = FACTORY->NewJSObject(function);

  // Set a propery
  obj->SetProperty(
      *prop_name, Smi::FromInt(23), NONE, kNonStrictMode)->ToObjectChecked();
  CHECK_EQ(Smi::FromInt(23), obj->GetProperty(*prop_name));

  // Check the map has changed
  CHECK(*initial_map != obj->map());
}


TEST(JSArray) {
  InitializeVM();

  v8::HandleScope sc;
  Handle<String> name = FACTORY->LookupUtf8Symbol("Array");
  Object* raw_object = Isolate::Current()->context()->global_object()->
      GetProperty(*name)->ToObjectChecked();
  Handle<JSFunction> function = Handle<JSFunction>(
      JSFunction::cast(raw_object));

  // Allocate the object.
  Handle<JSObject> object = FACTORY->NewJSObject(function);
  Handle<JSArray> array = Handle<JSArray>::cast(object);
  // We just initialized the VM, no heap allocation failure yet.
  array->Initialize(0)->ToObjectChecked();

  // Set array length to 0.
  array->SetElementsLength(Smi::FromInt(0))->ToObjectChecked();
  CHECK_EQ(Smi::FromInt(0), array->length());
  // Must be in fast mode.
  CHECK(array->HasFastSmiOrObjectElements());

  // array[length] = name.
  array->SetElement(0, *name, NONE, kNonStrictMode)->ToObjectChecked();
  CHECK_EQ(Smi::FromInt(1), array->length());
  CHECK_EQ(array->GetElement(0), *name);

  // Set array length with larger than smi value.
  Handle<Object> length =
      FACTORY->NewNumberFromUint(static_cast<uint32_t>(Smi::kMaxValue) + 1);
  array->SetElementsLength(*length)->ToObjectChecked();

  uint32_t int_length = 0;
  CHECK(length->ToArrayIndex(&int_length));
  CHECK_EQ(*length, array->length());
  CHECK(array->HasDictionaryElements());  // Must be in slow mode.

  // array[length] = name.
  array->SetElement(int_length, *name, NONE, kNonStrictMode)->ToObjectChecked();
  uint32_t new_int_length = 0;
  CHECK(array->length()->ToArrayIndex(&new_int_length));
  CHECK_EQ(static_cast<double>(int_length), new_int_length - 1);
  CHECK_EQ(array->GetElement(int_length), *name);
  CHECK_EQ(array->GetElement(0), *name);
}


TEST(JSObjectCopy) {
  InitializeVM();

  v8::HandleScope sc;
  String* object_symbol = String::cast(HEAP->Object_symbol());
  Object* raw_object = Isolate::Current()->context()->global_object()->
      GetProperty(object_symbol)->ToObjectChecked();
  JSFunction* object_function = JSFunction::cast(raw_object);
  Handle<JSFunction> constructor(object_function);
  Handle<JSObject> obj = FACTORY->NewJSObject(constructor);
  Handle<String> first = FACTORY->LookupUtf8Symbol("first");
  Handle<String> second = FACTORY->LookupUtf8Symbol("second");

  obj->SetProperty(
      *first, Smi::FromInt(1), NONE, kNonStrictMode)->ToObjectChecked();
  obj->SetProperty(
      *second, Smi::FromInt(2), NONE, kNonStrictMode)->ToObjectChecked();

  obj->SetElement(0, *first, NONE, kNonStrictMode)->ToObjectChecked();
  obj->SetElement(1, *second, NONE, kNonStrictMode)->ToObjectChecked();

  // Make the clone.
  Handle<JSObject> clone = Copy(obj);
  CHECK(!clone.is_identical_to(obj));

  CHECK_EQ(obj->GetElement(0), clone->GetElement(0));
  CHECK_EQ(obj->GetElement(1), clone->GetElement(1));

  CHECK_EQ(obj->GetProperty(*first), clone->GetProperty(*first));
  CHECK_EQ(obj->GetProperty(*second), clone->GetProperty(*second));

  // Flip the values.
  clone->SetProperty(
      *first, Smi::FromInt(2), NONE, kNonStrictMode)->ToObjectChecked();
  clone->SetProperty(
      *second, Smi::FromInt(1), NONE, kNonStrictMode)->ToObjectChecked();

  clone->SetElement(0, *second, NONE, kNonStrictMode)->ToObjectChecked();
  clone->SetElement(1, *first, NONE, kNonStrictMode)->ToObjectChecked();

  CHECK_EQ(obj->GetElement(1), clone->GetElement(0));
  CHECK_EQ(obj->GetElement(0), clone->GetElement(1));

  CHECK_EQ(obj->GetProperty(*second), clone->GetProperty(*first));
  CHECK_EQ(obj->GetProperty(*first), clone->GetProperty(*second));
}


TEST(StringAllocation) {
  InitializeVM();


  const unsigned char chars[] = { 0xe5, 0xa4, 0xa7 };
  for (int length = 0; length < 100; length++) {
    v8::HandleScope scope;
    char* non_ascii = NewArray<char>(3 * length + 1);
    char* ascii = NewArray<char>(length + 1);
    non_ascii[3 * length] = 0;
    ascii[length] = 0;
    for (int i = 0; i < length; i++) {
      ascii[i] = 'a';
      non_ascii[3 * i] = chars[0];
      non_ascii[3 * i + 1] = chars[1];
      non_ascii[3 * i + 2] = chars[2];
    }
    Handle<String> non_ascii_sym =
        FACTORY->LookupUtf8Symbol(Vector<const char>(non_ascii, 3 * length));
    CHECK_EQ(length, non_ascii_sym->length());
    Handle<String> ascii_sym =
        FACTORY->LookupOneByteSymbol(OneByteVector(ascii, length));
    CHECK_EQ(length, ascii_sym->length());
    Handle<String> non_ascii_str =
        FACTORY->NewStringFromUtf8(Vector<const char>(non_ascii, 3 * length));
    non_ascii_str->Hash();
    CHECK_EQ(length, non_ascii_str->length());
    Handle<String> ascii_str =
        FACTORY->NewStringFromUtf8(Vector<const char>(ascii, length));
    ascii_str->Hash();
    CHECK_EQ(length, ascii_str->length());
    DeleteArray(non_ascii);
    DeleteArray(ascii);
  }
}


static int ObjectsFoundInHeap(Handle<Object> objs[], int size) {
  // Count the number of objects found in the heap.
  int found_count = 0;
  HeapIterator iterator;
  for (HeapObject* obj = iterator.next(); obj != NULL; obj = iterator.next()) {
    for (int i = 0; i < size; i++) {
      if (*objs[i] == obj) {
        found_count++;
      }
    }
  }
  return found_count;
}


TEST(Iteration) {
  InitializeVM();
  v8::HandleScope scope;

  // Array of objects to scan haep for.
  const int objs_count = 6;
  Handle<Object> objs[objs_count];
  int next_objs_index = 0;

  // Allocate a JS array to OLD_POINTER_SPACE and NEW_SPACE
  objs[next_objs_index++] = FACTORY->NewJSArray(10);
  objs[next_objs_index++] = FACTORY->NewJSArray(10,
                                                FAST_HOLEY_ELEMENTS,
                                                TENURED);

  // Allocate a small string to OLD_DATA_SPACE and NEW_SPACE
  objs[next_objs_index++] =
      FACTORY->NewStringFromAscii(CStrVector("abcdefghij"));
  objs[next_objs_index++] =
      FACTORY->NewStringFromAscii(CStrVector("abcdefghij"), TENURED);

  // Allocate a large string (for large object space).
  int large_size = Page::kMaxNonCodeHeapObjectSize + 1;
  char* str = new char[large_size];
  for (int i = 0; i < large_size - 1; ++i) str[i] = 'a';
  str[large_size - 1] = '\0';
  objs[next_objs_index++] =
      FACTORY->NewStringFromAscii(CStrVector(str), TENURED);
  delete[] str;

  // Add a Map object to look for.
  objs[next_objs_index++] = Handle<Map>(HeapObject::cast(*objs[0])->map());

  CHECK_EQ(objs_count, next_objs_index);
  CHECK_EQ(objs_count, ObjectsFoundInHeap(objs, objs_count));
}


TEST(EmptyHandleEscapeFrom) {
  InitializeVM();

  v8::HandleScope scope;
  Handle<JSObject> runaway;

  {
      v8::HandleScope nested;
      Handle<JSObject> empty;
      runaway = empty.EscapeFrom(&nested);
  }

  CHECK(runaway.is_null());
}


static int LenFromSize(int size) {
  return (size - FixedArray::kHeaderSize) / kPointerSize;
}


TEST(Regression39128) {
  // Test case for crbug.com/39128.
  InitializeVM();

  // Increase the chance of 'bump-the-pointer' allocation in old space.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  v8::HandleScope scope;

  // The plan: create JSObject which references objects in new space.
  // Then clone this object (forcing it to go into old space) and check
  // that region dirty marks are updated correctly.

  // Step 1: prepare a map for the object.  We add 1 inobject property to it.
  Handle<JSFunction> object_ctor(
      Isolate::Current()->native_context()->object_function());
  CHECK(object_ctor->has_initial_map());
  Handle<Map> object_map(object_ctor->initial_map());
  // Create a map with single inobject property.
  Handle<Map> my_map = FACTORY->CopyMap(object_map, 1);
  int n_properties = my_map->inobject_properties();
  CHECK_GT(n_properties, 0);

  int object_size = my_map->instance_size();

  // Step 2: allocate a lot of objects so to almost fill new space: we need
  // just enough room to allocate JSObject and thus fill the newspace.

  int allocation_amount = Min(FixedArray::kMaxSize,
                              HEAP->MaxObjectSizeInNewSpace());
  int allocation_len = LenFromSize(allocation_amount);
  NewSpace* new_space = HEAP->new_space();
  Address* top_addr = new_space->allocation_top_address();
  Address* limit_addr = new_space->allocation_limit_address();
  while ((*limit_addr - *top_addr) > allocation_amount) {
    CHECK(!HEAP->always_allocate());
    Object* array = HEAP->AllocateFixedArray(allocation_len)->ToObjectChecked();
    CHECK(!array->IsFailure());
    CHECK(new_space->Contains(array));
  }

  // Step 3: now allocate fixed array and JSObject to fill the whole new space.
  int to_fill = static_cast<int>(*limit_addr - *top_addr - object_size);
  int fixed_array_len = LenFromSize(to_fill);
  CHECK(fixed_array_len < FixedArray::kMaxLength);

  CHECK(!HEAP->always_allocate());
  Object* array = HEAP->AllocateFixedArray(fixed_array_len)->ToObjectChecked();
  CHECK(!array->IsFailure());
  CHECK(new_space->Contains(array));

  Object* object = HEAP->AllocateJSObjectFromMap(*my_map)->ToObjectChecked();
  CHECK(new_space->Contains(object));
  JSObject* jsobject = JSObject::cast(object);
  CHECK_EQ(0, FixedArray::cast(jsobject->elements())->length());
  CHECK_EQ(0, jsobject->properties()->length());
  // Create a reference to object in new space in jsobject.
  jsobject->FastPropertyAtPut(-1, array);

  CHECK_EQ(0, static_cast<int>(*limit_addr - *top_addr));

  // Step 4: clone jsobject, but force always allocate first to create a clone
  // in old pointer space.
  Address old_pointer_space_top = HEAP->old_pointer_space()->top();
  AlwaysAllocateScope aa_scope;
  Object* clone_obj = HEAP->CopyJSObject(jsobject)->ToObjectChecked();
  JSObject* clone = JSObject::cast(clone_obj);
  if (clone->address() != old_pointer_space_top) {
    // Alas, got allocated from free list, we cannot do checks.
    return;
  }
  CHECK(HEAP->old_pointer_space()->Contains(clone->address()));
}


TEST(TestCodeFlushing) {
  // If we do not flush code this test is invalid.
  if (!FLAG_flush_code) return;
  i::FLAG_allow_natives_syntax = true;
  InitializeVM();
  v8::HandleScope scope;
  const char* source = "function foo() {"
                       "  var x = 42;"
                       "  var y = 42;"
                       "  var z = x + y;"
                       "};"
                       "foo()";
  Handle<String> foo_name = FACTORY->LookupUtf8Symbol("foo");

  // This compile will add the code to the compilation cache.
  { v8::HandleScope scope;
    CompileRun(source);
  }

  // Check function is compiled.
  Object* func_value = Isolate::Current()->context()->global_object()->
      GetProperty(*foo_name)->ToObjectChecked();
  CHECK(func_value->IsJSFunction());
  Handle<JSFunction> function(JSFunction::cast(func_value));
  CHECK(function->shared()->is_compiled());

  // The code will survive at least two GCs.
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);
  CHECK(function->shared()->is_compiled());

  // Simulate several GCs that use full marking.
  const int kAgingThreshold = 6;
  for (int i = 0; i < kAgingThreshold; i++) {
    HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);
  }

  // foo should no longer be in the compilation cache
  CHECK(!function->shared()->is_compiled() || function->IsOptimized());
  CHECK(!function->is_compiled() || function->IsOptimized());
  // Call foo to get it recompiled.
  CompileRun("foo()");
  CHECK(function->shared()->is_compiled());
  CHECK(function->is_compiled());
}


TEST(TestCodeFlushingIncremental) {
  // If we do not flush code this test is invalid.
  if (!FLAG_flush_code || !FLAG_flush_code_incrementally) return;
  i::FLAG_allow_natives_syntax = true;
  InitializeVM();
  v8::HandleScope scope;
  const char* source = "function foo() {"
                       "  var x = 42;"
                       "  var y = 42;"
                       "  var z = x + y;"
                       "};"
                       "foo()";
  Handle<String> foo_name = FACTORY->LookupUtf8Symbol("foo");

  // This compile will add the code to the compilation cache.
  { v8::HandleScope scope;
    CompileRun(source);
  }

  // Check function is compiled.
  Object* func_value = Isolate::Current()->context()->global_object()->
      GetProperty(*foo_name)->ToObjectChecked();
  CHECK(func_value->IsJSFunction());
  Handle<JSFunction> function(JSFunction::cast(func_value));
  CHECK(function->shared()->is_compiled());

  // The code will survive at least two GCs.
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);
  CHECK(function->shared()->is_compiled());

  // Simulate several GCs that use incremental marking.
  const int kAgingThreshold = 6;
  for (int i = 0; i < kAgingThreshold; i++) {
    SimulateIncrementalMarking();
    HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  }
  CHECK(!function->shared()->is_compiled() || function->IsOptimized());
  CHECK(!function->is_compiled() || function->IsOptimized());

  // This compile will compile the function again.
  { v8::HandleScope scope;
    CompileRun("foo();");
  }

  // Simulate several GCs that use incremental marking but make sure
  // the loop breaks once the function is enqueued as a candidate.
  for (int i = 0; i < kAgingThreshold; i++) {
    SimulateIncrementalMarking();
    if (!function->next_function_link()->IsUndefined()) break;
    HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  }

  // Force optimization while incremental marking is active and while
  // the function is enqueued as a candidate.
  { v8::HandleScope scope;
    CompileRun("%OptimizeFunctionOnNextCall(foo); foo();");
  }

  // Simulate one final GC to make sure the candidate queue is sane.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  CHECK(function->shared()->is_compiled() || !function->IsOptimized());
  CHECK(function->is_compiled() || !function->IsOptimized());
}


TEST(TestCodeFlushingIncrementalScavenge) {
  // If we do not flush code this test is invalid.
  if (!FLAG_flush_code || !FLAG_flush_code_incrementally) return;
  i::FLAG_allow_natives_syntax = true;
  InitializeVM();
  v8::HandleScope scope;
  const char* source = "var foo = function() {"
                       "  var x = 42;"
                       "  var y = 42;"
                       "  var z = x + y;"
                       "};"
                       "foo();"
                       "var bar = function() {"
                       "  var x = 23;"
                       "};"
                       "bar();";
  Handle<String> foo_name = FACTORY->LookupUtf8Symbol("foo");
  Handle<String> bar_name = FACTORY->LookupUtf8Symbol("bar");

  // Perfrom one initial GC to enable code flushing.
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);

  // This compile will add the code to the compilation cache.
  { v8::HandleScope scope;
    CompileRun(source);
  }

  // Check functions are compiled.
  Object* func_value = Isolate::Current()->context()->global_object()->
      GetProperty(*foo_name)->ToObjectChecked();
  CHECK(func_value->IsJSFunction());
  Handle<JSFunction> function(JSFunction::cast(func_value));
  CHECK(function->shared()->is_compiled());
  Object* func_value2 = Isolate::Current()->context()->global_object()->
      GetProperty(*bar_name)->ToObjectChecked();
  CHECK(func_value2->IsJSFunction());
  Handle<JSFunction> function2(JSFunction::cast(func_value2));
  CHECK(function2->shared()->is_compiled());

  // Clear references to functions so that one of them can die.
  { v8::HandleScope scope;
    CompileRun("foo = 0; bar = 0;");
  }

  // Bump the code age so that flushing is triggered while the function
  // object is still located in new-space.
  const int kAgingThreshold = 6;
  for (int i = 0; i < kAgingThreshold; i++) {
    function->shared()->code()->MakeOlder(static_cast<MarkingParity>(i % 2));
    function2->shared()->code()->MakeOlder(static_cast<MarkingParity>(i % 2));
  }

  // Simulate incremental marking so that the functions are enqueued as
  // code flushing candidates. Then kill one of the functions. Finally
  // perform a scavenge while incremental marking is still running.
  SimulateIncrementalMarking();
  *function2.location() = NULL;
  HEAP->CollectGarbage(NEW_SPACE, "test scavenge while marking");

  // Simulate one final GC to make sure the candidate queue is sane.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  CHECK(!function->shared()->is_compiled() || function->IsOptimized());
  CHECK(!function->is_compiled() || function->IsOptimized());
}


TEST(TestCodeFlushingIncrementalAbort) {
  // If we do not flush code this test is invalid.
  if (!FLAG_flush_code || !FLAG_flush_code_incrementally) return;
  i::FLAG_allow_natives_syntax = true;
  InitializeVM();
  v8::HandleScope scope;
  const char* source = "function foo() {"
                       "  var x = 42;"
                       "  var y = 42;"
                       "  var z = x + y;"
                       "};"
                       "foo()";
  Handle<String> foo_name = FACTORY->LookupUtf8Symbol("foo");

  // This compile will add the code to the compilation cache.
  { v8::HandleScope scope;
    CompileRun(source);
  }

  // Check function is compiled.
  Object* func_value = Isolate::Current()->context()->global_object()->
      GetProperty(*foo_name)->ToObjectChecked();
  CHECK(func_value->IsJSFunction());
  Handle<JSFunction> function(JSFunction::cast(func_value));
  CHECK(function->shared()->is_compiled());

  // The code will survive at least two GCs.
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);
  CHECK(function->shared()->is_compiled());

  // Bump the code age so that flushing is triggered.
  const int kAgingThreshold = 6;
  for (int i = 0; i < kAgingThreshold; i++) {
    function->shared()->code()->MakeOlder(static_cast<MarkingParity>(i % 2));
  }

  // Simulate incremental marking so that the function is enqueued as
  // code flushing candidate.
  SimulateIncrementalMarking();

  // Enable the debugger and add a breakpoint while incremental marking
  // is running so that incremental marking aborts and code flushing is
  // disabled.
  int position = 0;
  Handle<Object> breakpoint_object(Smi::FromInt(0));
  ISOLATE->debug()->SetBreakPoint(function, breakpoint_object, &position);
  ISOLATE->debug()->ClearAllBreakPoints();

  // Force optimization now that code flushing is disabled.
  { v8::HandleScope scope;
    CompileRun("%OptimizeFunctionOnNextCall(foo); foo();");
  }

  // Simulate one final GC to make sure the candidate queue is sane.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  CHECK(function->shared()->is_compiled() || !function->IsOptimized());
  CHECK(function->is_compiled() || !function->IsOptimized());
}


// Count the number of native contexts in the weak list of native contexts.
int CountNativeContexts() {
  int count = 0;
  Object* object = HEAP->native_contexts_list();
  while (!object->IsUndefined()) {
    count++;
    object = Context::cast(object)->get(Context::NEXT_CONTEXT_LINK);
  }
  return count;
}


// Count the number of user functions in the weak list of optimized
// functions attached to a native context.
static int CountOptimizedUserFunctions(v8::Handle<v8::Context> context) {
  int count = 0;
  Handle<Context> icontext = v8::Utils::OpenHandle(*context);
  Object* object = icontext->get(Context::OPTIMIZED_FUNCTIONS_LIST);
  while (object->IsJSFunction() && !JSFunction::cast(object)->IsBuiltin()) {
    count++;
    object = JSFunction::cast(object)->next_function_link();
  }
  return count;
}


TEST(TestInternalWeakLists) {
  v8::V8::Initialize();

  // Some flags turn Scavenge collections into Mark-sweep collections
  // and hence are incompatible with this test case.
  if (FLAG_gc_global || FLAG_stress_compaction) return;

  static const int kNumTestContexts = 10;

  v8::HandleScope scope;
  v8::Persistent<v8::Context> ctx[kNumTestContexts];

  CHECK_EQ(0, CountNativeContexts());

  // Create a number of global contests which gets linked together.
  for (int i = 0; i < kNumTestContexts; i++) {
    ctx[i] = v8::Context::New();

    bool opt = (FLAG_always_opt && i::V8::UseCrankshaft());

    CHECK_EQ(i + 1, CountNativeContexts());

    ctx[i]->Enter();

    // Create a handle scope so no function objects get stuch in the outer
    // handle scope
    v8::HandleScope scope;
    const char* source = "function f1() { };"
                         "function f2() { };"
                         "function f3() { };"
                         "function f4() { };"
                         "function f5() { };";
    CompileRun(source);
    CHECK_EQ(0, CountOptimizedUserFunctions(ctx[i]));
    CompileRun("f1()");
    CHECK_EQ(opt ? 1 : 0, CountOptimizedUserFunctions(ctx[i]));
    CompileRun("f2()");
    CHECK_EQ(opt ? 2 : 0, CountOptimizedUserFunctions(ctx[i]));
    CompileRun("f3()");
    CHECK_EQ(opt ? 3 : 0, CountOptimizedUserFunctions(ctx[i]));
    CompileRun("f4()");
    CHECK_EQ(opt ? 4 : 0, CountOptimizedUserFunctions(ctx[i]));
    CompileRun("f5()");
    CHECK_EQ(opt ? 5 : 0, CountOptimizedUserFunctions(ctx[i]));

    // Remove function f1, and
    CompileRun("f1=null");

    // Scavenge treats these references as strong.
    for (int j = 0; j < 10; j++) {
      HEAP->PerformScavenge();
      CHECK_EQ(opt ? 5 : 0, CountOptimizedUserFunctions(ctx[i]));
    }

    // Mark compact handles the weak references.
    ISOLATE->compilation_cache()->Clear();
    HEAP->CollectAllGarbage(Heap::kNoGCFlags);
    CHECK_EQ(opt ? 4 : 0, CountOptimizedUserFunctions(ctx[i]));

    // Get rid of f3 and f5 in the same way.
    CompileRun("f3=null");
    for (int j = 0; j < 10; j++) {
      HEAP->PerformScavenge();
      CHECK_EQ(opt ? 4 : 0, CountOptimizedUserFunctions(ctx[i]));
    }
    HEAP->CollectAllGarbage(Heap::kNoGCFlags);
    CHECK_EQ(opt ? 3 : 0, CountOptimizedUserFunctions(ctx[i]));
    CompileRun("f5=null");
    for (int j = 0; j < 10; j++) {
      HEAP->PerformScavenge();
      CHECK_EQ(opt ? 3 : 0, CountOptimizedUserFunctions(ctx[i]));
    }
    HEAP->CollectAllGarbage(Heap::kNoGCFlags);
    CHECK_EQ(opt ? 2 : 0, CountOptimizedUserFunctions(ctx[i]));

    ctx[i]->Exit();
  }

  // Force compilation cache cleanup.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  // Dispose the native contexts one by one.
  for (int i = 0; i < kNumTestContexts; i++) {
    ctx[i].Dispose(ctx[i]->GetIsolate());
    ctx[i].Clear();

    // Scavenge treats these references as strong.
    for (int j = 0; j < 10; j++) {
      HEAP->PerformScavenge();
      CHECK_EQ(kNumTestContexts - i, CountNativeContexts());
    }

    // Mark compact handles the weak references.
    HEAP->CollectAllGarbage(Heap::kNoGCFlags);
    CHECK_EQ(kNumTestContexts - i - 1, CountNativeContexts());
  }

  CHECK_EQ(0, CountNativeContexts());
}


// Count the number of native contexts in the weak list of native contexts
// causing a GC after the specified number of elements.
static int CountNativeContextsWithGC(int n) {
  int count = 0;
  Handle<Object> object(HEAP->native_contexts_list());
  while (!object->IsUndefined()) {
    count++;
    if (count == n) HEAP->CollectAllGarbage(Heap::kNoGCFlags);
    object =
        Handle<Object>(Context::cast(*object)->get(Context::NEXT_CONTEXT_LINK));
  }
  return count;
}


// Count the number of user functions in the weak list of optimized
// functions attached to a native context causing a GC after the
// specified number of elements.
static int CountOptimizedUserFunctionsWithGC(v8::Handle<v8::Context> context,
                                             int n) {
  int count = 0;
  Handle<Context> icontext = v8::Utils::OpenHandle(*context);
  Handle<Object> object(icontext->get(Context::OPTIMIZED_FUNCTIONS_LIST));
  while (object->IsJSFunction() &&
         !Handle<JSFunction>::cast(object)->IsBuiltin()) {
    count++;
    if (count == n) HEAP->CollectAllGarbage(Heap::kNoGCFlags);
    object = Handle<Object>(
        Object::cast(JSFunction::cast(*object)->next_function_link()));
  }
  return count;
}


TEST(TestInternalWeakListsTraverseWithGC) {
  v8::V8::Initialize();

  static const int kNumTestContexts = 10;

  v8::HandleScope scope;
  v8::Persistent<v8::Context> ctx[kNumTestContexts];

  CHECK_EQ(0, CountNativeContexts());

  // Create an number of contexts and check the length of the weak list both
  // with and without GCs while iterating the list.
  for (int i = 0; i < kNumTestContexts; i++) {
    ctx[i] = v8::Context::New();
    CHECK_EQ(i + 1, CountNativeContexts());
    CHECK_EQ(i + 1, CountNativeContextsWithGC(i / 2 + 1));
  }

  bool opt = (FLAG_always_opt && i::V8::UseCrankshaft());

  // Compile a number of functions the length of the weak list of optimized
  // functions both with and without GCs while iterating the list.
  ctx[0]->Enter();
  const char* source = "function f1() { };"
                       "function f2() { };"
                       "function f3() { };"
                       "function f4() { };"
                       "function f5() { };";
  CompileRun(source);
  CHECK_EQ(0, CountOptimizedUserFunctions(ctx[0]));
  CompileRun("f1()");
  CHECK_EQ(opt ? 1 : 0, CountOptimizedUserFunctions(ctx[0]));
  CHECK_EQ(opt ? 1 : 0, CountOptimizedUserFunctionsWithGC(ctx[0], 1));
  CompileRun("f2()");
  CHECK_EQ(opt ? 2 : 0, CountOptimizedUserFunctions(ctx[0]));
  CHECK_EQ(opt ? 2 : 0, CountOptimizedUserFunctionsWithGC(ctx[0], 1));
  CompileRun("f3()");
  CHECK_EQ(opt ? 3 : 0, CountOptimizedUserFunctions(ctx[0]));
  CHECK_EQ(opt ? 3 : 0, CountOptimizedUserFunctionsWithGC(ctx[0], 1));
  CompileRun("f4()");
  CHECK_EQ(opt ? 4 : 0, CountOptimizedUserFunctions(ctx[0]));
  CHECK_EQ(opt ? 4 : 0, CountOptimizedUserFunctionsWithGC(ctx[0], 2));
  CompileRun("f5()");
  CHECK_EQ(opt ? 5 : 0, CountOptimizedUserFunctions(ctx[0]));
  CHECK_EQ(opt ? 5 : 0, CountOptimizedUserFunctionsWithGC(ctx[0], 4));

  ctx[0]->Exit();
}


TEST(TestSizeOfObjects) {
  v8::V8::Initialize();

  // Get initial heap size after several full GCs, which will stabilize
  // the heap size and return with sweeping finished completely.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  CHECK(HEAP->old_pointer_space()->IsLazySweepingComplete());
  int initial_size = static_cast<int>(HEAP->SizeOfObjects());

  {
    // Allocate objects on several different old-space pages so that
    // lazy sweeping kicks in for subsequent GC runs.
    AlwaysAllocateScope always_allocate;
    int filler_size = static_cast<int>(FixedArray::SizeFor(8192));
    for (int i = 1; i <= 100; i++) {
      HEAP->AllocateFixedArray(8192, TENURED)->ToObjectChecked();
      CHECK_EQ(initial_size + i * filler_size,
               static_cast<int>(HEAP->SizeOfObjects()));
    }
  }

  // The heap size should go back to initial size after a full GC, even
  // though sweeping didn't finish yet.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  // Normally sweeping would not be complete here, but no guarantees.

  CHECK_EQ(initial_size, static_cast<int>(HEAP->SizeOfObjects()));

  // Advancing the sweeper step-wise should not change the heap size.
  while (!HEAP->old_pointer_space()->IsLazySweepingComplete()) {
    HEAP->old_pointer_space()->AdvanceSweeper(KB);
    CHECK_EQ(initial_size, static_cast<int>(HEAP->SizeOfObjects()));
  }
}


TEST(TestSizeOfObjectsVsHeapIteratorPrecision) {
  InitializeVM();
  HEAP->EnsureHeapIsIterable();
  intptr_t size_of_objects_1 = HEAP->SizeOfObjects();
  HeapIterator iterator;
  intptr_t size_of_objects_2 = 0;
  for (HeapObject* obj = iterator.next();
       obj != NULL;
       obj = iterator.next()) {
    if (!obj->IsFreeSpace()) {
      size_of_objects_2 += obj->Size();
    }
  }
  // Delta must be within 5% of the larger result.
  // TODO(gc): Tighten this up by distinguishing between byte
  // arrays that are real and those that merely mark free space
  // on the heap.
  if (size_of_objects_1 > size_of_objects_2) {
    intptr_t delta = size_of_objects_1 - size_of_objects_2;
    PrintF("Heap::SizeOfObjects: %" V8_PTR_PREFIX "d, "
           "Iterator: %" V8_PTR_PREFIX "d, "
           "delta: %" V8_PTR_PREFIX "d\n",
           size_of_objects_1, size_of_objects_2, delta);
    CHECK_GT(size_of_objects_1 / 20, delta);
  } else {
    intptr_t delta = size_of_objects_2 - size_of_objects_1;
    PrintF("Heap::SizeOfObjects: %" V8_PTR_PREFIX "d, "
           "Iterator: %" V8_PTR_PREFIX "d, "
           "delta: %" V8_PTR_PREFIX "d\n",
           size_of_objects_1, size_of_objects_2, delta);
    CHECK_GT(size_of_objects_2 / 20, delta);
  }
}


static void FillUpNewSpace(NewSpace* new_space) {
  // Fill up new space to the point that it is completely full. Make sure
  // that the scavenger does not undo the filling.
  v8::HandleScope scope;
  AlwaysAllocateScope always_allocate;
  intptr_t available = new_space->EffectiveCapacity() - new_space->Size();
  intptr_t number_of_fillers = (available / FixedArray::SizeFor(32)) - 1;
  for (intptr_t i = 0; i < number_of_fillers; i++) {
    CHECK(HEAP->InNewSpace(*FACTORY->NewFixedArray(32, NOT_TENURED)));
  }
}


TEST(GrowAndShrinkNewSpace) {
  InitializeVM();
  NewSpace* new_space = HEAP->new_space();

  if (HEAP->ReservedSemiSpaceSize() == HEAP->InitialSemiSpaceSize() ||
      HEAP->MaxSemiSpaceSize() == HEAP->InitialSemiSpaceSize()) {
    // The max size cannot exceed the reserved size, since semispaces must be
    // always within the reserved space.  We can't test new space growing and
    // shrinking if the reserved size is the same as the minimum (initial) size.
    return;
  }

  // Explicitly growing should double the space capacity.
  intptr_t old_capacity, new_capacity;
  old_capacity = new_space->Capacity();
  new_space->Grow();
  new_capacity = new_space->Capacity();
  CHECK(2 * old_capacity == new_capacity);

  old_capacity = new_space->Capacity();
  FillUpNewSpace(new_space);
  new_capacity = new_space->Capacity();
  CHECK(old_capacity == new_capacity);

  // Explicitly shrinking should not affect space capacity.
  old_capacity = new_space->Capacity();
  new_space->Shrink();
  new_capacity = new_space->Capacity();
  CHECK(old_capacity == new_capacity);

  // Let the scavenger empty the new space.
  HEAP->CollectGarbage(NEW_SPACE);
  CHECK_LE(new_space->Size(), old_capacity);

  // Explicitly shrinking should halve the space capacity.
  old_capacity = new_space->Capacity();
  new_space->Shrink();
  new_capacity = new_space->Capacity();
  CHECK(old_capacity == 2 * new_capacity);

  // Consecutive shrinking should not affect space capacity.
  old_capacity = new_space->Capacity();
  new_space->Shrink();
  new_space->Shrink();
  new_space->Shrink();
  new_capacity = new_space->Capacity();
  CHECK(old_capacity == new_capacity);
}


TEST(CollectingAllAvailableGarbageShrinksNewSpace) {
  InitializeVM();

  if (HEAP->ReservedSemiSpaceSize() == HEAP->InitialSemiSpaceSize() ||
      HEAP->MaxSemiSpaceSize() == HEAP->InitialSemiSpaceSize()) {
    // The max size cannot exceed the reserved size, since semispaces must be
    // always within the reserved space.  We can't test new space growing and
    // shrinking if the reserved size is the same as the minimum (initial) size.
    return;
  }

  v8::HandleScope scope;
  NewSpace* new_space = HEAP->new_space();
  intptr_t old_capacity, new_capacity;
  old_capacity = new_space->Capacity();
  new_space->Grow();
  new_capacity = new_space->Capacity();
  CHECK(2 * old_capacity == new_capacity);
  FillUpNewSpace(new_space);
  HEAP->CollectAllAvailableGarbage();
  new_capacity = new_space->Capacity();
  CHECK(old_capacity == new_capacity);
}


static int NumberOfGlobalObjects() {
  int count = 0;
  HeapIterator iterator;
  for (HeapObject* obj = iterator.next(); obj != NULL; obj = iterator.next()) {
    if (obj->IsGlobalObject()) count++;
  }
  return count;
}


// Test that we don't embed maps from foreign contexts into
// optimized code.
TEST(LeakNativeContextViaMap) {
  i::FLAG_allow_natives_syntax = true;
  v8::HandleScope outer_scope;
  v8::Persistent<v8::Context> ctx1 = v8::Context::New();
  v8::Persistent<v8::Context> ctx2 = v8::Context::New();
  ctx1->Enter();

  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(4, NumberOfGlobalObjects());

  {
    v8::HandleScope inner_scope;
    CompileRun("var v = {x: 42}");
    v8::Local<v8::Value> v = ctx1->Global()->Get(v8_str("v"));
    ctx2->Enter();
    ctx2->Global()->Set(v8_str("o"), v);
    v8::Local<v8::Value> res = CompileRun(
        "function f() { return o.x; }"
        "for (var i = 0; i < 10; ++i) f();"
        "%OptimizeFunctionOnNextCall(f);"
        "f();");
    CHECK_EQ(42, res->Int32Value());
    ctx2->Global()->Set(v8_str("o"), v8::Int32::New(0));
    ctx2->Exit();
    ctx1->Exit();
    ctx1.Dispose(ctx1->GetIsolate());
    v8::V8::ContextDisposedNotification();
  }
  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(2, NumberOfGlobalObjects());
  ctx2.Dispose(ctx2->GetIsolate());
  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(0, NumberOfGlobalObjects());
}


// Test that we don't embed functions from foreign contexts into
// optimized code.
TEST(LeakNativeContextViaFunction) {
  i::FLAG_allow_natives_syntax = true;
  v8::HandleScope outer_scope;
  v8::Persistent<v8::Context> ctx1 = v8::Context::New();
  v8::Persistent<v8::Context> ctx2 = v8::Context::New();
  ctx1->Enter();

  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(4, NumberOfGlobalObjects());

  {
    v8::HandleScope inner_scope;
    CompileRun("var v = function() { return 42; }");
    v8::Local<v8::Value> v = ctx1->Global()->Get(v8_str("v"));
    ctx2->Enter();
    ctx2->Global()->Set(v8_str("o"), v);
    v8::Local<v8::Value> res = CompileRun(
        "function f(x) { return x(); }"
        "for (var i = 0; i < 10; ++i) f(o);"
        "%OptimizeFunctionOnNextCall(f);"
        "f(o);");
    CHECK_EQ(42, res->Int32Value());
    ctx2->Global()->Set(v8_str("o"), v8::Int32::New(0));
    ctx2->Exit();
    ctx1->Exit();
    ctx1.Dispose(ctx1->GetIsolate());
    v8::V8::ContextDisposedNotification();
  }
  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(2, NumberOfGlobalObjects());
  ctx2.Dispose(ctx2->GetIsolate());
  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(0, NumberOfGlobalObjects());
}


TEST(LeakNativeContextViaMapKeyed) {
  i::FLAG_allow_natives_syntax = true;
  v8::HandleScope outer_scope;
  v8::Persistent<v8::Context> ctx1 = v8::Context::New();
  v8::Persistent<v8::Context> ctx2 = v8::Context::New();
  ctx1->Enter();

  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(4, NumberOfGlobalObjects());

  {
    v8::HandleScope inner_scope;
    CompileRun("var v = [42, 43]");
    v8::Local<v8::Value> v = ctx1->Global()->Get(v8_str("v"));
    ctx2->Enter();
    ctx2->Global()->Set(v8_str("o"), v);
    v8::Local<v8::Value> res = CompileRun(
        "function f() { return o[0]; }"
        "for (var i = 0; i < 10; ++i) f();"
        "%OptimizeFunctionOnNextCall(f);"
        "f();");
    CHECK_EQ(42, res->Int32Value());
    ctx2->Global()->Set(v8_str("o"), v8::Int32::New(0));
    ctx2->Exit();
    ctx1->Exit();
    ctx1.Dispose(ctx1->GetIsolate());
    v8::V8::ContextDisposedNotification();
  }
  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(2, NumberOfGlobalObjects());
  ctx2.Dispose(ctx2->GetIsolate());
  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(0, NumberOfGlobalObjects());
}


TEST(LeakNativeContextViaMapProto) {
  i::FLAG_allow_natives_syntax = true;
  v8::HandleScope outer_scope;
  v8::Persistent<v8::Context> ctx1 = v8::Context::New();
  v8::Persistent<v8::Context> ctx2 = v8::Context::New();
  ctx1->Enter();

  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(4, NumberOfGlobalObjects());

  {
    v8::HandleScope inner_scope;
    CompileRun("var v = { y: 42}");
    v8::Local<v8::Value> v = ctx1->Global()->Get(v8_str("v"));
    ctx2->Enter();
    ctx2->Global()->Set(v8_str("o"), v);
    v8::Local<v8::Value> res = CompileRun(
        "function f() {"
        "  var p = {x: 42};"
        "  p.__proto__ = o;"
        "  return p.x;"
        "}"
        "for (var i = 0; i < 10; ++i) f();"
        "%OptimizeFunctionOnNextCall(f);"
        "f();");
    CHECK_EQ(42, res->Int32Value());
    ctx2->Global()->Set(v8_str("o"), v8::Int32::New(0));
    ctx2->Exit();
    ctx1->Exit();
    ctx1.Dispose(ctx1->GetIsolate());
    v8::V8::ContextDisposedNotification();
  }
  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(2, NumberOfGlobalObjects());
  ctx2.Dispose(ctx2->GetIsolate());
  HEAP->CollectAllAvailableGarbage();
  CHECK_EQ(0, NumberOfGlobalObjects());
}


TEST(InstanceOfStubWriteBarrier) {
  i::FLAG_allow_natives_syntax = true;
#ifdef VERIFY_HEAP
  i::FLAG_verify_heap = true;
#endif

  InitializeVM();
  if (!i::V8::UseCrankshaft()) return;
  if (i::FLAG_force_marking_deque_overflows) return;
  v8::HandleScope outer_scope;

  {
    v8::HandleScope scope;
    CompileRun(
        "function foo () { }"
        "function mkbar () { return new (new Function(\"\")) (); }"
        "function f (x) { return (x instanceof foo); }"
        "function g () { f(mkbar()); }"
        "f(new foo()); f(new foo());"
        "%OptimizeFunctionOnNextCall(f);"
        "f(new foo()); g();");
  }

  IncrementalMarking* marking = HEAP->incremental_marking();
  marking->Abort();
  marking->Start();

  Handle<JSFunction> f =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Function>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));

  CHECK(f->IsOptimized());

  while (!Marking::IsBlack(Marking::MarkBitFrom(f->code())) &&
         !marking->IsStopped()) {
    // Discard any pending GC requests otherwise we will get GC when we enter
    // code below.
    marking->Step(MB, IncrementalMarking::NO_GC_VIA_STACK_GUARD);
  }

  CHECK(marking->IsMarking());

  {
    v8::HandleScope scope;
    v8::Handle<v8::Object> global = v8::Context::GetCurrent()->Global();
    v8::Handle<v8::Function> g =
        v8::Handle<v8::Function>::Cast(global->Get(v8_str("g")));
    g->Call(global, 0, NULL);
  }

  HEAP->incremental_marking()->set_should_hurry(true);
  HEAP->CollectGarbage(OLD_POINTER_SPACE);
}


TEST(PrototypeTransitionClearing) {
  InitializeVM();
  v8::HandleScope scope;

  CompileRun(
      "var base = {};"
      "var live = [];"
      "for (var i = 0; i < 10; i++) {"
      "  var object = {};"
      "  var prototype = {};"
      "  object.__proto__ = prototype;"
      "  if (i >= 3) live.push(object, prototype);"
      "}");

  Handle<JSObject> baseObject =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Object>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("base"))));

  // Verify that only dead prototype transitions are cleared.
  CHECK_EQ(10, baseObject->map()->NumberOfProtoTransitions());
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  const int transitions = 10 - 3;
  CHECK_EQ(transitions, baseObject->map()->NumberOfProtoTransitions());

  // Verify that prototype transitions array was compacted.
  FixedArray* trans = baseObject->map()->GetPrototypeTransitions();
  for (int i = 0; i < transitions; i++) {
    int j = Map::kProtoTransitionHeaderSize +
        i * Map::kProtoTransitionElementsPerEntry;
    CHECK(trans->get(j + Map::kProtoTransitionMapOffset)->IsMap());
    Object* proto = trans->get(j + Map::kProtoTransitionPrototypeOffset);
    CHECK(proto->IsTheHole() || proto->IsJSObject());
  }

  // Make sure next prototype is placed on an old-space evacuation candidate.
  Handle<JSObject> prototype;
  PagedSpace* space = HEAP->old_pointer_space();
  {
    AlwaysAllocateScope always_allocate;
    SimulateFullSpace(space);
    prototype = FACTORY->NewJSArray(32 * KB, FAST_HOLEY_ELEMENTS, TENURED);
  }

  // Add a prototype on an evacuation candidate and verify that transition
  // clearing correctly records slots in prototype transition array.
  i::FLAG_always_compact = true;
  Handle<Map> map(baseObject->map());
  CHECK(!space->LastPage()->Contains(
      map->GetPrototypeTransitions()->address()));
  CHECK(space->LastPage()->Contains(prototype->address()));
  baseObject->SetPrototype(*prototype, false)->ToObjectChecked();
  CHECK(map->GetPrototypeTransition(*prototype)->IsMap());
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  CHECK(map->GetPrototypeTransition(*prototype)->IsMap());
}


TEST(ResetSharedFunctionInfoCountersDuringIncrementalMarking) {
  i::FLAG_allow_natives_syntax = true;
#ifdef VERIFY_HEAP
  i::FLAG_verify_heap = true;
#endif

  InitializeVM();
  if (!i::V8::UseCrankshaft()) return;
  v8::HandleScope outer_scope;

  {
    v8::HandleScope scope;
    CompileRun(
        "function f () {"
        "  var s = 0;"
        "  for (var i = 0; i < 100; i++)  s += i;"
        "  return s;"
        "}"
        "f(); f();"
        "%OptimizeFunctionOnNextCall(f);"
        "f();");
  }
  Handle<JSFunction> f =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Function>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));
  CHECK(f->IsOptimized());

  IncrementalMarking* marking = HEAP->incremental_marking();
  marking->Abort();
  marking->Start();

  // The following two calls will increment HEAP->global_ic_age().
  const int kLongIdlePauseInMs = 1000;
  v8::V8::ContextDisposedNotification();
  v8::V8::IdleNotification(kLongIdlePauseInMs);

  while (!marking->IsStopped() && !marking->IsComplete()) {
    marking->Step(1 * MB, IncrementalMarking::NO_GC_VIA_STACK_GUARD);
  }
  if (!marking->IsStopped() || marking->should_hurry()) {
    // We don't normally finish a GC via Step(), we normally finish by
    // setting the stack guard and then do the final steps in the stack
    // guard interrupt.  But here we didn't ask for that, and there is no
    // JS code running to trigger the interrupt, so we explicitly finalize
    // here.
    HEAP->CollectAllGarbage(Heap::kNoGCFlags,
                            "Test finalizing incremental mark-sweep");
  }

  CHECK_EQ(HEAP->global_ic_age(), f->shared()->ic_age());
  CHECK_EQ(0, f->shared()->opt_count());
  CHECK_EQ(0, f->shared()->code()->profiler_ticks());
}


TEST(ResetSharedFunctionInfoCountersDuringMarkSweep) {
  i::FLAG_allow_natives_syntax = true;
#ifdef VERIFY_HEAP
  i::FLAG_verify_heap = true;
#endif

  InitializeVM();
  if (!i::V8::UseCrankshaft()) return;
  v8::HandleScope outer_scope;

  {
    v8::HandleScope scope;
    CompileRun(
        "function f () {"
        "  var s = 0;"
        "  for (var i = 0; i < 100; i++)  s += i;"
        "  return s;"
        "}"
        "f(); f();"
        "%OptimizeFunctionOnNextCall(f);"
        "f();");
  }
  Handle<JSFunction> f =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Function>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));
  CHECK(f->IsOptimized());

  HEAP->incremental_marking()->Abort();

  // The following two calls will increment HEAP->global_ic_age().
  // Since incremental marking is off, IdleNotification will do full GC.
  const int kLongIdlePauseInMs = 1000;
  v8::V8::ContextDisposedNotification();
  v8::V8::IdleNotification(kLongIdlePauseInMs);

  CHECK_EQ(HEAP->global_ic_age(), f->shared()->ic_age());
  CHECK_EQ(0, f->shared()->opt_count());
  CHECK_EQ(0, f->shared()->code()->profiler_ticks());
}


// Test that HAllocateObject will always return an object in new-space.
TEST(OptimizedAllocationAlwaysInNewSpace) {
  i::FLAG_allow_natives_syntax = true;
  InitializeVM();
  if (!i::V8::UseCrankshaft() || i::FLAG_always_opt) return;
  if (i::FLAG_gc_global || i::FLAG_stress_compaction) return;
  v8::HandleScope scope;

  SimulateFullSpace(HEAP->new_space());
  AlwaysAllocateScope always_allocate;
  v8::Local<v8::Value> res = CompileRun(
      "function c(x) {"
      "  this.x = x;"
      "  for (var i = 0; i < 32; i++) {"
      "    this['x' + i] = x;"
      "  }"
      "}"
      "function f(x) { return new c(x); };"
      "f(1); f(2); f(3);"
      "%OptimizeFunctionOnNextCall(f);"
      "f(4);");
  CHECK_EQ(4, res->ToObject()->GetRealNamedProperty(v8_str("x"))->Int32Value());

  Handle<JSObject> o =
      v8::Utils::OpenHandle(*v8::Handle<v8::Object>::Cast(res));

  CHECK(HEAP->InNewSpace(*o));
}


static int CountMapTransitions(Map* map) {
  return map->transitions()->number_of_transitions();
}


// Test that map transitions are cleared and maps are collected with
// incremental marking as well.
TEST(Regress1465) {
  i::FLAG_allow_natives_syntax = true;
  i::FLAG_trace_incremental_marking = true;
  InitializeVM();
  v8::HandleScope scope;
  static const int transitions_count = 256;

  {
    AlwaysAllocateScope always_allocate;
    for (int i = 0; i < transitions_count; i++) {
      EmbeddedVector<char, 64> buffer;
      OS::SNPrintF(buffer, "var o = new Object; o.prop%d = %d;", i, i);
      CompileRun(buffer.start());
    }
    CompileRun("var root = new Object;");
  }

  Handle<JSObject> root =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Object>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("root"))));

  // Count number of live transitions before marking.
  int transitions_before = CountMapTransitions(root->map());
  CompileRun("%DebugPrint(root);");
  CHECK_EQ(transitions_count, transitions_before);

  SimulateIncrementalMarking();
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  // Count number of live transitions after marking.  Note that one transition
  // is left, because 'o' still holds an instance of one transition target.
  int transitions_after = CountMapTransitions(root->map());
  CompileRun("%DebugPrint(root);");
  CHECK_EQ(1, transitions_after);
}


TEST(Regress2143a) {
  i::FLAG_collect_maps = true;
  i::FLAG_incremental_marking = true;
  InitializeVM();
  v8::HandleScope scope;

  // Prepare a map transition from the root object together with a yet
  // untransitioned root object.
  CompileRun("var root = new Object;"
             "root.foo = 0;"
             "root = new Object;");

  SimulateIncrementalMarking();

  // Compile a StoreIC that performs the prepared map transition. This
  // will restart incremental marking and should make sure the root is
  // marked grey again.
  CompileRun("function f(o) {"
             "  o.foo = 0;"
             "}"
             "f(new Object);"
             "f(root);");

  // This bug only triggers with aggressive IC clearing.
  HEAP->AgeInlineCaches();

  // Explicitly request GC to perform final marking step and sweeping.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  Handle<JSObject> root =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Object>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("root"))));

  // The root object should be in a sane state.
  CHECK(root->IsJSObject());
  CHECK(root->map()->IsMap());
}


TEST(Regress2143b) {
  i::FLAG_collect_maps = true;
  i::FLAG_incremental_marking = true;
  i::FLAG_allow_natives_syntax = true;
  InitializeVM();
  v8::HandleScope scope;

  // Prepare a map transition from the root object together with a yet
  // untransitioned root object.
  CompileRun("var root = new Object;"
             "root.foo = 0;"
             "root = new Object;");

  SimulateIncrementalMarking();

  // Compile an optimized LStoreNamedField that performs the prepared
  // map transition. This will restart incremental marking and should
  // make sure the root is marked grey again.
  CompileRun("function f(o) {"
             "  o.foo = 0;"
             "}"
             "f(new Object);"
             "f(new Object);"
             "%OptimizeFunctionOnNextCall(f);"
             "f(root);"
             "%DeoptimizeFunction(f);");

  // This bug only triggers with aggressive IC clearing.
  HEAP->AgeInlineCaches();

  // Explicitly request GC to perform final marking step and sweeping.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  Handle<JSObject> root =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Object>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("root"))));

  // The root object should be in a sane state.
  CHECK(root->IsJSObject());
  CHECK(root->map()->IsMap());
}


TEST(ReleaseOverReservedPages) {
  i::FLAG_trace_gc = true;
  // The optimizer can allocate stuff, messing up the test.
  i::FLAG_crankshaft = false;
  i::FLAG_always_opt = false;
  InitializeVM();
  v8::HandleScope scope;
  static const int number_of_test_pages = 20;

  // Prepare many pages with low live-bytes count.
  PagedSpace* old_pointer_space = HEAP->old_pointer_space();
  CHECK_EQ(1, old_pointer_space->CountTotalPages());
  for (int i = 0; i < number_of_test_pages; i++) {
    AlwaysAllocateScope always_allocate;
    SimulateFullSpace(old_pointer_space);
    FACTORY->NewFixedArray(1, TENURED);
  }
  CHECK_EQ(number_of_test_pages + 1, old_pointer_space->CountTotalPages());

  // Triggering one GC will cause a lot of garbage to be discovered but
  // even spread across all allocated pages.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags, "triggered for preparation");
  CHECK_GE(number_of_test_pages + 1, old_pointer_space->CountTotalPages());

  // Triggering subsequent GCs should cause at least half of the pages
  // to be released to the OS after at most two cycles.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags, "triggered by test 1");
  CHECK_GE(number_of_test_pages + 1, old_pointer_space->CountTotalPages());
  HEAP->CollectAllGarbage(Heap::kNoGCFlags, "triggered by test 2");
  CHECK_GE(number_of_test_pages + 1, old_pointer_space->CountTotalPages() * 2);

  // Triggering a last-resort GC should cause all pages to be released to the
  // OS so that other processes can seize the memory.  If we get a failure here
  // where there are 2 pages left instead of 1, then we should increase the
  // size of the first page a little in SizeOfFirstPage in spaces.cc.  The
  // first page should be small in order to reduce memory used when the VM
  // boots, but if the 20 small arrays don't fit on the first page then that's
  // an indication that it is too small.
  HEAP->CollectAllAvailableGarbage("triggered really hard");
  CHECK_EQ(1, old_pointer_space->CountTotalPages());
}


TEST(Regress2237) {
  InitializeVM();
  v8::HandleScope scope;
  Handle<String> slice(HEAP->empty_string());

  {
    // Generate a parent that lives in new-space.
    v8::HandleScope inner_scope;
    const char* c = "This text is long enough to trigger sliced strings.";
    Handle<String> s = FACTORY->NewStringFromAscii(CStrVector(c));
    CHECK(s->IsSeqOneByteString());
    CHECK(HEAP->InNewSpace(*s));

    // Generate a sliced string that is based on the above parent and
    // lives in old-space.
    SimulateFullSpace(HEAP->new_space());
    AlwaysAllocateScope always_allocate;
    Handle<String> t = FACTORY->NewProperSubString(s, 5, 35);
    CHECK(t->IsSlicedString());
    CHECK(!HEAP->InNewSpace(*t));
    *slice.location() = *t.location();
  }

  CHECK(SlicedString::cast(*slice)->parent()->IsSeqOneByteString());
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  CHECK(SlicedString::cast(*slice)->parent()->IsSeqOneByteString());
}


#ifdef OBJECT_PRINT
TEST(PrintSharedFunctionInfo) {
  InitializeVM();
  v8::HandleScope scope;
  const char* source = "f = function() { return 987654321; }\n"
                       "g = function() { return 123456789; }\n";
  CompileRun(source);
  Handle<JSFunction> g =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Function>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("g"))));

  AssertNoAllocation no_alloc;
  g->shared()->PrintLn();
}
#endif  // OBJECT_PRINT


TEST(Regress2211) {
  InitializeVM();
  v8::HandleScope scope;

  v8::Handle<v8::String> value = v8_str("val string");
  Smi* hash = Smi::FromInt(321);
  Heap* heap = Isolate::Current()->heap();

  for (int i = 0; i < 2; i++) {
    // Store identity hash first and common hidden property second.
    v8::Handle<v8::Object> obj = v8::Object::New();
    Handle<JSObject> internal_obj = v8::Utils::OpenHandle(*obj);
    CHECK(internal_obj->HasFastProperties());

    // In the first iteration, set hidden value first and identity hash second.
    // In the second iteration, reverse the order.
    if (i == 0) obj->SetHiddenValue(v8_str("key string"), value);
    MaybeObject* maybe_obj = internal_obj->SetIdentityHash(hash,
                                                           ALLOW_CREATION);
    CHECK(!maybe_obj->IsFailure());
    if (i == 1) obj->SetHiddenValue(v8_str("key string"), value);

    // Check values.
    CHECK_EQ(hash,
             internal_obj->GetHiddenProperty(heap->identity_hash_symbol()));
    CHECK(value->Equals(obj->GetHiddenValue(v8_str("key string"))));

    // Check size.
    DescriptorArray* descriptors = internal_obj->map()->instance_descriptors();
    ObjectHashTable* hashtable = ObjectHashTable::cast(
        internal_obj->FastPropertyAt(descriptors->GetFieldIndex(0)));
    // HashTable header (5) and 4 initial entries (8).
    CHECK_LE(hashtable->SizeFor(hashtable->length()), 13 * kPointerSize);
  }
}


TEST(IncrementalMarkingClearsTypeFeedbackCells) {
  if (i::FLAG_always_opt) return;
  InitializeVM();
  v8::HandleScope scope;
  v8::Local<v8::Value> fun1, fun2;

  {
    LocalContext env;
    CompileRun("function fun() {};");
    fun1 = env->Global()->Get(v8_str("fun"));
  }

  {
    LocalContext env;
    CompileRun("function fun() {};");
    fun2 = env->Global()->Get(v8_str("fun"));
  }

  // Prepare function f that contains type feedback for closures
  // originating from two different native contexts.
  v8::Context::GetCurrent()->Global()->Set(v8_str("fun1"), fun1);
  v8::Context::GetCurrent()->Global()->Set(v8_str("fun2"), fun2);
  CompileRun("function f(a, b) { a(); b(); } f(fun1, fun2);");
  Handle<JSFunction> f =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Function>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));
  Handle<TypeFeedbackCells> cells(TypeFeedbackInfo::cast(
      f->shared()->code()->type_feedback_info())->type_feedback_cells());

  CHECK_EQ(2, cells->CellCount());
  CHECK(cells->Cell(0)->value()->IsJSFunction());
  CHECK(cells->Cell(1)->value()->IsJSFunction());

  SimulateIncrementalMarking();
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  CHECK_EQ(2, cells->CellCount());
  CHECK(cells->Cell(0)->value()->IsTheHole());
  CHECK(cells->Cell(1)->value()->IsTheHole());
}


static Code* FindFirstIC(Code* code, Code::Kind kind) {
  int mask = RelocInfo::ModeMask(RelocInfo::CODE_TARGET) |
             RelocInfo::ModeMask(RelocInfo::CONSTRUCT_CALL) |
             RelocInfo::ModeMask(RelocInfo::CODE_TARGET_WITH_ID) |
             RelocInfo::ModeMask(RelocInfo::CODE_TARGET_CONTEXT);
  for (RelocIterator it(code, mask); !it.done(); it.next()) {
    RelocInfo* info = it.rinfo();
    Code* target = Code::GetCodeFromTargetAddress(info->target_address());
    if (target->is_inline_cache_stub() && target->kind() == kind) {
      return target;
    }
  }
  return NULL;
}


TEST(IncrementalMarkingPreservesMonomorhpicIC) {
  if (i::FLAG_always_opt) return;
  InitializeVM();
  v8::HandleScope scope;

  // Prepare function f that contains a monomorphic IC for object
  // originating from the same native context.
  CompileRun("function fun() { this.x = 1; }; var obj = new fun();"
             "function f(o) { return o.x; } f(obj); f(obj);");
  Handle<JSFunction> f =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Function>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));

  Code* ic_before = FindFirstIC(f->shared()->code(), Code::LOAD_IC);
  CHECK(ic_before->ic_state() == MONOMORPHIC);

  SimulateIncrementalMarking();
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  Code* ic_after = FindFirstIC(f->shared()->code(), Code::LOAD_IC);
  CHECK(ic_after->ic_state() == MONOMORPHIC);
}


TEST(IncrementalMarkingClearsMonomorhpicIC) {
  if (i::FLAG_always_opt) return;
  InitializeVM();
  v8::HandleScope scope;
  v8::Local<v8::Value> obj1;

  {
    LocalContext env;
    CompileRun("function fun() { this.x = 1; }; var obj = new fun();");
    obj1 = env->Global()->Get(v8_str("obj"));
  }

  // Prepare function f that contains a monomorphic IC for object
  // originating from a different native context.
  v8::Context::GetCurrent()->Global()->Set(v8_str("obj1"), obj1);
  CompileRun("function f(o) { return o.x; } f(obj1); f(obj1);");
  Handle<JSFunction> f =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Function>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));

  Code* ic_before = FindFirstIC(f->shared()->code(), Code::LOAD_IC);
  CHECK(ic_before->ic_state() == MONOMORPHIC);

  // Fire context dispose notification.
  v8::V8::ContextDisposedNotification();
  SimulateIncrementalMarking();
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  Code* ic_after = FindFirstIC(f->shared()->code(), Code::LOAD_IC);
  CHECK(ic_after->ic_state() == UNINITIALIZED);
}


TEST(IncrementalMarkingClearsPolymorhpicIC) {
  if (i::FLAG_always_opt) return;
  InitializeVM();
  v8::HandleScope scope;
  v8::Local<v8::Value> obj1, obj2;

  {
    LocalContext env;
    CompileRun("function fun() { this.x = 1; }; var obj = new fun();");
    obj1 = env->Global()->Get(v8_str("obj"));
  }

  {
    LocalContext env;
    CompileRun("function fun() { this.x = 2; }; var obj = new fun();");
    obj2 = env->Global()->Get(v8_str("obj"));
  }

  // Prepare function f that contains a polymorphic IC for objects
  // originating from two different native contexts.
  v8::Context::GetCurrent()->Global()->Set(v8_str("obj1"), obj1);
  v8::Context::GetCurrent()->Global()->Set(v8_str("obj2"), obj2);
  CompileRun("function f(o) { return o.x; } f(obj1); f(obj1); f(obj2);");
  Handle<JSFunction> f =
      v8::Utils::OpenHandle(
          *v8::Handle<v8::Function>::Cast(
              v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));

  Code* ic_before = FindFirstIC(f->shared()->code(), Code::LOAD_IC);
  CHECK(ic_before->ic_state() == MEGAMORPHIC);

  // Fire context dispose notification.
  v8::V8::ContextDisposedNotification();
  SimulateIncrementalMarking();
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  Code* ic_after = FindFirstIC(f->shared()->code(), Code::LOAD_IC);
  CHECK(ic_after->ic_state() == UNINITIALIZED);
}


class SourceResource: public v8::String::ExternalAsciiStringResource {
 public:
  explicit SourceResource(const char* data)
    : data_(data), length_(strlen(data)) { }

  virtual void Dispose() {
    i::DeleteArray(data_);
    data_ = NULL;
  }

  const char* data() const { return data_; }

  size_t length() const { return length_; }

  bool IsDisposed() { return data_ == NULL; }

 private:
  const char* data_;
  size_t length_;
};


void ReleaseStackTraceDataTest(const char* source) {
  // Test that the data retained by the Error.stack accessor is released
  // after the first time the accessor is fired.  We use external string
  // to check whether the data is being released since the external string
  // resource's callback is fired when the external string is GC'ed.
  InitializeVM();
  v8::HandleScope scope;
  SourceResource* resource = new SourceResource(i::StrDup(source));
  {
    v8::HandleScope scope;
    v8::Handle<v8::String> source_string = v8::String::NewExternal(resource);
    v8::Script::Compile(source_string)->Run();
    CHECK(!resource->IsDisposed());
  }
  HEAP->CollectAllAvailableGarbage();

  // External source has been released.
  CHECK(resource->IsDisposed());
  delete resource;
}


TEST(ReleaseStackTraceData) {
  static const char* source1 = "var error = null;            "
  /* Normal Error */           "try {                        "
                               "  throw new Error();         "
                               "} catch (e) {                "
                               "  error = e;                 "
                               "}                            ";
  static const char* source2 = "var error = null;            "
  /* Stack overflow */         "try {                        "
                               "  (function f() { f(); })(); "
                               "} catch (e) {                "
                               "  error = e;                 "
                               "}                            ";
  ReleaseStackTraceDataTest(source1);
  ReleaseStackTraceDataTest(source2);
}


TEST(Regression144230) {
  InitializeVM();
  v8::HandleScope scope;

  // First make sure that the uninitialized CallIC stub is on a single page
  // that will later be selected as an evacuation candidate.
  {
    v8::HandleScope inner_scope;
    AlwaysAllocateScope always_allocate;
    SimulateFullSpace(HEAP->code_space());
    ISOLATE->stub_cache()->ComputeCallInitialize(9, RelocInfo::CODE_TARGET);
  }

  // Second compile a CallIC and execute it once so that it gets patched to
  // the pre-monomorphic stub. These code objects are on yet another page.
  {
    v8::HandleScope inner_scope;
    AlwaysAllocateScope always_allocate;
    SimulateFullSpace(HEAP->code_space());
    CompileRun("var o = { f:function(a,b,c,d,e,f,g,h,i) {}};"
               "function call() { o.f(1,2,3,4,5,6,7,8,9); };"
               "call();");
  }

  // Third we fill up the last page of the code space so that it does not get
  // chosen as an evacuation candidate.
  {
    v8::HandleScope inner_scope;
    AlwaysAllocateScope always_allocate;
    CompileRun("for (var i = 0; i < 2000; i++) {"
               "  eval('function f' + i + '() { return ' + i +'; };' +"
               "       'f' + i + '();');"
               "}");
  }
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  // Fourth is the tricky part. Make sure the code containing the CallIC is
  // visited first without clearing the IC. The shared function info is then
  // visited later, causing the CallIC to be cleared.
  Handle<String> name = FACTORY->LookupUtf8Symbol("call");
  Handle<GlobalObject> global(ISOLATE->context()->global_object());
  MaybeObject* maybe_call = global->GetProperty(*name);
  JSFunction* call = JSFunction::cast(maybe_call->ToObjectChecked());
  USE(global->SetProperty(*name, Smi::FromInt(0), NONE, kNonStrictMode));
  ISOLATE->compilation_cache()->Clear();
  call->shared()->set_ic_age(HEAP->global_ic_age() + 1);
  Handle<Object> call_code(call->code());
  Handle<Object> call_function(call);

  // Now we are ready to mess up the heap.
  HEAP->CollectAllGarbage(Heap::kReduceMemoryFootprintMask);

  // Either heap verification caught the problem already or we go kaboom once
  // the CallIC is executed the next time.
  USE(global->SetProperty(*name, *call_function, NONE, kNonStrictMode));
  CompileRun("call();");
}


TEST(Regress159140) {
  i::FLAG_allow_natives_syntax = true;
  i::FLAG_flush_code_incrementally = true;
  InitializeVM();
  v8::HandleScope scope;

  // Perform one initial GC to enable code flushing.
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);

  // Prepare several closures that are all eligible for code flushing
  // because all reachable ones are not optimized. Make sure that the
  // optimized code object is directly reachable through a handle so
  // that it is marked black during incremental marking.
  Handle<Code> code;
  {
    HandleScope inner_scope;
    CompileRun("function h(x) {}"
               "function mkClosure() {"
               "  return function(x) { return x + 1; };"
               "}"
               "var f = mkClosure();"
               "var g = mkClosure();"
               "f(1); f(2);"
               "g(1); g(2);"
               "h(1); h(2);"
               "%OptimizeFunctionOnNextCall(f); f(3);"
               "%OptimizeFunctionOnNextCall(h); h(3);");

    Handle<JSFunction> f =
        v8::Utils::OpenHandle(
            *v8::Handle<v8::Function>::Cast(
                v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));
    CHECK(f->is_compiled());
    CompileRun("f = null;");

    Handle<JSFunction> g =
        v8::Utils::OpenHandle(
            *v8::Handle<v8::Function>::Cast(
                v8::Context::GetCurrent()->Global()->Get(v8_str("g"))));
    CHECK(g->is_compiled());
    const int kAgingThreshold = 6;
    for (int i = 0; i < kAgingThreshold; i++) {
      g->code()->MakeOlder(static_cast<MarkingParity>(i % 2));
    }

    code = inner_scope.CloseAndEscape(Handle<Code>(f->code()));
  }

  // Simulate incremental marking so that the functions are enqueued as
  // code flushing candidates. Then optimize one function. Finally
  // finish the GC to complete code flushing.
  SimulateIncrementalMarking();
  CompileRun("%OptimizeFunctionOnNextCall(g); g(3);");
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  // Unoptimized code is missing and the deoptimizer will go ballistic.
  CompileRun("g('bozo');");
}


TEST(Regress165495) {
  i::FLAG_allow_natives_syntax = true;
  i::FLAG_flush_code_incrementally = true;
  InitializeVM();
  v8::HandleScope scope;

  // Perform one initial GC to enable code flushing.
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);

  // Prepare an optimized closure that the optimized code map will get
  // populated. Then age the unoptimized code to trigger code flushing
  // but make sure the optimized code is unreachable.
  {
    HandleScope inner_scope;
    CompileRun("function mkClosure() {"
               "  return function(x) { return x + 1; };"
               "}"
               "var f = mkClosure();"
               "f(1); f(2);"
               "%OptimizeFunctionOnNextCall(f); f(3);");

    Handle<JSFunction> f =
        v8::Utils::OpenHandle(
            *v8::Handle<v8::Function>::Cast(
                v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));
    CHECK(f->is_compiled());
    const int kAgingThreshold = 6;
    for (int i = 0; i < kAgingThreshold; i++) {
      f->shared()->code()->MakeOlder(static_cast<MarkingParity>(i % 2));
    }

    CompileRun("f = null;");
  }

  // Simulate incremental marking so that unoptimized code is flushed
  // even though it still is cached in the optimized code map.
  SimulateIncrementalMarking();
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);

  // Make a new closure that will get code installed from the code map.
  // Unoptimized code is missing and the deoptimizer will go ballistic.
  CompileRun("var g = mkClosure(); g('bozo');");
}


TEST(Regress169209) {
  i::FLAG_stress_compaction = false;
  i::FLAG_allow_natives_syntax = true;
  i::FLAG_flush_code_incrementally = true;
  InitializeVM();
  v8::HandleScope scope;

  // Perform one initial GC to enable code flushing.
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);

  // Prepare a shared function info eligible for code flushing for which
  // the unoptimized code will be replaced during optimization.
  Handle<SharedFunctionInfo> shared1;
  {
    HandleScope inner_scope;
    CompileRun("function f() { return 'foobar'; }"
               "function g(x) { if (x) f(); }"
               "f();"
               "g(false);"
               "g(false);");

    Handle<JSFunction> f =
        v8::Utils::OpenHandle(
            *v8::Handle<v8::Function>::Cast(
                v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));
    CHECK(f->is_compiled());
    const int kAgingThreshold = 6;
    for (int i = 0; i < kAgingThreshold; i++) {
      f->shared()->code()->MakeOlder(static_cast<MarkingParity>(i % 2));
    }

    shared1 = inner_scope.CloseAndEscape(handle(f->shared(), ISOLATE));
  }

  // Prepare a shared function info eligible for code flushing that will
  // represent the dangling tail of the candidate list.
  Handle<SharedFunctionInfo> shared2;
  {
    HandleScope inner_scope;
    CompileRun("function flushMe() { return 0; }"
               "flushMe(1);");

    Handle<JSFunction> f =
        v8::Utils::OpenHandle(
            *v8::Handle<v8::Function>::Cast(
                v8::Context::GetCurrent()->Global()->Get(v8_str("flushMe"))));
    CHECK(f->is_compiled());
    const int kAgingThreshold = 6;
    for (int i = 0; i < kAgingThreshold; i++) {
      f->shared()->code()->MakeOlder(static_cast<MarkingParity>(i % 2));
    }

    shared2 = inner_scope.CloseAndEscape(handle(f->shared(), ISOLATE));
  }

  // Simulate incremental marking and collect code flushing candidates.
  SimulateIncrementalMarking();
  CHECK(shared1->code()->gc_metadata() != NULL);

  // Optimize function and make sure the unoptimized code is replaced.
#ifdef DEBUG
  FLAG_stop_at = "f";
#endif
  CompileRun("%OptimizeFunctionOnNextCall(g);"
             "g(false);");

  // Finish garbage collection cycle.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  CHECK(shared1->code()->gc_metadata() == NULL);
}


// Helper function that simulates a fill new-space in the heap.
static inline void AllocateAllButNBytes(v8::internal::NewSpace* space,
                                        int extra_bytes) {
  int space_remaining = static_cast<int>(
      *space->allocation_limit_address() - *space->allocation_top_address());
  CHECK(space_remaining >= extra_bytes);
  int new_linear_size = space_remaining - extra_bytes;
  v8::internal::MaybeObject* maybe = space->AllocateRaw(new_linear_size);
  v8::internal::FreeListNode* node = v8::internal::FreeListNode::cast(maybe);
  node->set_size(space->heap(), new_linear_size);
}


TEST(Regress169928) {
  i::FLAG_allow_natives_syntax = true;
  i::FLAG_crankshaft = false;
  InitializeVM();
  v8::HandleScope scope;

  // Some flags turn Scavenge collections into Mark-sweep collections
  // and hence are incompatible with this test case.
  if (FLAG_gc_global || FLAG_stress_compaction) return;

  // Prepare the environment
  CompileRun("function fastliteralcase(literal, value) {"
             "    literal[0] = value;"
             "    return literal;"
             "}"
             "function get_standard_literal() {"
             "    var literal = [1, 2, 3];"
             "    return literal;"
             "}"
             "obj = fastliteralcase(get_standard_literal(), 1);"
             "obj = fastliteralcase(get_standard_literal(), 1.5);"
             "obj = fastliteralcase(get_standard_literal(), 2);");

  // prepare the heap
  v8::Local<v8::String> mote_code_string =
      v8_str("fastliteralcase(mote, 2.5);");

  v8::Local<v8::String> array_name = v8_str("mote");
  v8::Context::GetCurrent()->Global()->Set(array_name, v8::Int32::New(0));

  // First make sure we flip spaces
  HEAP->CollectGarbage(NEW_SPACE);

  // Allocate the object.
  Handle<FixedArray> array_data = FACTORY->NewFixedArray(2, NOT_TENURED);
  array_data->set(0, Smi::FromInt(1));
  array_data->set(1, Smi::FromInt(2));

  AllocateAllButNBytes(HEAP->new_space(),
                       JSArray::kSize + AllocationSiteInfo::kSize +
                       kPointerSize);

  Handle<JSArray> array = FACTORY->NewJSArrayWithElements(array_data,
                                                          FAST_SMI_ELEMENTS,
                                                          NOT_TENURED);

  CHECK_EQ(Smi::FromInt(2), array->length());
  CHECK(array->HasFastSmiOrObjectElements());

  // We need filler the size of AllocationSiteInfo object, plus an extra
  // fill pointer value.
  MaybeObject* maybe_object = HEAP->AllocateRaw(
      AllocationSiteInfo::kSize + kPointerSize, NEW_SPACE, OLD_POINTER_SPACE);
  Object* obj = NULL;
  CHECK(maybe_object->ToObject(&obj));
  Address addr_obj = reinterpret_cast<Address>(
      reinterpret_cast<byte*>(obj - kHeapObjectTag));
  HEAP->CreateFillerObjectAt(addr_obj,
                             AllocationSiteInfo::kSize + kPointerSize);

  // Give the array a name, making sure not to allocate strings.
  v8::Handle<v8::Object> array_obj = v8::Utils::ToLocal(array);
  v8::Context::GetCurrent()->Global()->Set(array_name, array_obj);

  // This should crash with a protection violation if we are running a build
  // with the bug.
  AlwaysAllocateScope aa_scope;
  v8::Script::Compile(mote_code_string)->Run();
}


TEST(Regress168801) {
  i::FLAG_always_compact = true;
  i::FLAG_cache_optimized_code = false;
  i::FLAG_allow_natives_syntax = true;
  i::FLAG_flush_code_incrementally = true;
  InitializeVM();
  v8::HandleScope scope;

  // Perform one initial GC to enable code flushing.
  HEAP->CollectAllGarbage(Heap::kAbortIncrementalMarkingMask);

  // Ensure the code ends up on an evacuation candidate.
  SimulateFullSpace(HEAP->code_space());

  // Prepare an unoptimized function that is eligible for code flushing.
  Handle<JSFunction> function;
  {
    HandleScope inner_scope;
    CompileRun("function mkClosure() {"
               "  return function(x) { return x + 1; };"
               "}"
               "var f = mkClosure();"
               "f(1); f(2);");

    Handle<JSFunction> f =
        v8::Utils::OpenHandle(
            *v8::Handle<v8::Function>::Cast(
                v8::Context::GetCurrent()->Global()->Get(v8_str("f"))));
    CHECK(f->is_compiled());
    const int kAgingThreshold = 6;
    for (int i = 0; i < kAgingThreshold; i++) {
      f->shared()->code()->MakeOlder(static_cast<MarkingParity>(i % 2));
    }

    function = inner_scope.CloseAndEscape(handle(*f, ISOLATE));
  }

  // Simulate incremental marking so that unoptimized function is enqueued as a
  // candidate for code flushing. The shared function info however will not be
  // explicitly enqueued.
  SimulateIncrementalMarking();

  // Now optimize the function so that it is taken off the candidate list.
  {
    HandleScope inner_scope;
    CompileRun("%OptimizeFunctionOnNextCall(f); f(3);");
  }

  // This cycle will bust the heap and subsequent cycles will go ballistic.
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
  HEAP->CollectAllGarbage(Heap::kNoGCFlags);
}
