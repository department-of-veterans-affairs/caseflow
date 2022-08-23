// Copyright 2006-2009 the V8 project authors. All rights reserved.
//
// Tests of logging functions from log.h

#ifdef __linux__
#include <math.h>
#include <pthread.h>
#include <signal.h>
#include <unistd.h>
#endif  // __linux__

#include "v8.h"
#include "log.h"
#include "cpu-profiler.h"
#include "natives.h"
#include "v8threads.h"
#include "v8utils.h"
#include "cctest.h"
#include "vm-state-inl.h"

using v8::internal::Address;
using v8::internal::EmbeddedVector;
using v8::internal::Logger;
using v8::internal::StrLength;

namespace {


class ScopedLoggerInitializer {
 public:
  explicit ScopedLoggerInitializer(bool prof_lazy)
      : saved_log_(i::FLAG_log),
        saved_prof_lazy_(i::FLAG_prof_lazy),
        saved_prof_(i::FLAG_prof),
        saved_prof_auto_(i::FLAG_prof_auto),
        temp_file_(NULL),
        // Need to run this prior to creating the scope.
        trick_to_run_init_flags_(init_flags_(prof_lazy)),
        scope_(),
        env_(v8::Context::New()) {
    env_->Enter();
  }

  ~ScopedLoggerInitializer() {
    env_->Exit();
    LOGGER->TearDown();
    if (temp_file_ != NULL) fclose(temp_file_);
    i::FLAG_prof_lazy = saved_prof_lazy_;
    i::FLAG_prof = saved_prof_;
    i::FLAG_prof_auto = saved_prof_auto_;
    i::FLAG_log = saved_log_;
  }

  v8::Handle<v8::Context>& env() { return env_; }

  FILE* StopLoggingGetTempFile() {
    temp_file_ = LOGGER->TearDown();
    CHECK_NE(NULL, temp_file_);
    fflush(temp_file_);
    rewind(temp_file_);
    return temp_file_;
  }

 private:
  static bool init_flags_(bool prof_lazy) {
    i::FLAG_log = true;
    i::FLAG_prof = true;
    i::FLAG_prof_lazy = prof_lazy;
    i::FLAG_prof_auto = false;
    i::FLAG_logfile = i::Log::kLogToTemporaryFile;
    return prof_lazy;
  }

  const bool saved_log_;
  const bool saved_prof_lazy_;
  const bool saved_prof_;
  const bool saved_prof_auto_;
  FILE* temp_file_;
  const bool trick_to_run_init_flags_;
  v8::HandleScope scope_;
  v8::Handle<v8::Context> env_;

  DISALLOW_COPY_AND_ASSIGN(ScopedLoggerInitializer);
};

}  // namespace


static const char* StrNStr(const char* s1, const char* s2, int n) {
  if (s1[n] == '\0') return strstr(s1, s2);
  i::ScopedVector<char> str(n + 1);
  i::OS::StrNCpy(str, s1, static_cast<size_t>(n));
  str[n] = '\0';
  char* found = strstr(str.start(), s2);
  return found != NULL ? s1 + (found - str.start()) : NULL;
}


TEST(ProfLazyMode) {
  ScopedLoggerInitializer initialize_logger(true);

  if (!i::V8::UseCrankshaft()) return;

  LOGGER->StringEvent("test-start", "");
  CompileRun("var a = (function(x) { return x + 1; })(10);");
  LOGGER->StringEvent("test-profiler-start", "");
  v8::V8::ResumeProfiler();
  CompileRun(
      "var b = (function(x) { return x + 2; })(10);\n"
      "var c = (function(x) { return x + 3; })(10);\n"
      "var d = (function(x) { return x + 4; })(10);\n"
      "var e = (function(x) { return x + 5; })(10);");
  v8::V8::PauseProfiler();
  LOGGER->StringEvent("test-profiler-stop", "");
  CompileRun("var f = (function(x) { return x + 6; })(10);");
  // Check that profiling can be resumed again.
  LOGGER->StringEvent("test-profiler-start-2", "");
  v8::V8::ResumeProfiler();
  CompileRun(
      "var g = (function(x) { return x + 7; })(10);\n"
      "var h = (function(x) { return x + 8; })(10);\n"
      "var i = (function(x) { return x + 9; })(10);\n"
      "var j = (function(x) { return x + 10; })(10);");
  v8::V8::PauseProfiler();
  LOGGER->StringEvent("test-profiler-stop-2", "");
  LOGGER->StringEvent("test-stop", "");

  bool exists = false;
  i::Vector<const char> log(
      i::ReadFile(initialize_logger.StopLoggingGetTempFile(), &exists, true));
  CHECK(exists);

  const char* test_start_position =
      StrNStr(log.start(), "test-start,", log.length());
  CHECK_NE(NULL, test_start_position);
  const char* test_profiler_start_position =
      StrNStr(log.start(), "test-profiler-start,", log.length());
  CHECK_NE(NULL, test_profiler_start_position);
  CHECK_GT(test_profiler_start_position, test_start_position);
  const char* test_profiler_stop_position =
      StrNStr(log.start(), "test-profiler-stop,", log.length());
  CHECK_NE(NULL, test_profiler_stop_position);
  CHECK_GT(test_profiler_stop_position, test_profiler_start_position);
  const char* test_profiler_start_2_position =
      StrNStr(log.start(), "test-profiler-start-2,", log.length());
  CHECK_NE(NULL, test_profiler_start_2_position);
  CHECK_GT(test_profiler_start_2_position, test_profiler_stop_position);

  // Nothing must be logged until profiling is resumed.
  CHECK_EQ(NULL, StrNStr(test_start_position,
                         "code-creation,",
                         static_cast<int>(test_profiler_start_position -
                                          test_start_position)));
  // Nothing must be logged while profiling is suspended.
  CHECK_EQ(NULL, StrNStr(test_profiler_stop_position,
                         "code-creation,",
                         static_cast<int>(test_profiler_start_2_position -
                                          test_profiler_stop_position)));
}


// BUG(913). Need to implement support for profiling multiple VM threads.
#if 0

namespace {

class LoopingThread : public v8::internal::Thread {
 public:
  explicit LoopingThread(v8::internal::Isolate* isolate)
      : v8::internal::Thread(isolate),
        semaphore_(v8::internal::OS::CreateSemaphore(0)),
        run_(true) {
  }

  virtual ~LoopingThread() { delete semaphore_; }

  void Run() {
    self_ = pthread_self();
    RunLoop();
  }

  void SendSigProf() { pthread_kill(self_, SIGPROF); }

  void Stop() { run_ = false; }

  bool WaitForRunning() { return semaphore_->Wait(1000000); }

 protected:
  bool IsRunning() { return run_; }

  virtual void RunLoop() = 0;

  void SetV8ThreadId() {
    v8_thread_id_ = v8::V8::GetCurrentThreadId();
  }

  void SignalRunning() { semaphore_->Signal(); }

 private:
  v8::internal::Semaphore* semaphore_;
  bool run_;
  pthread_t self_;
  int v8_thread_id_;
};


class LoopingJsThread : public LoopingThread {
 public:
  explicit LoopingJsThread(v8::internal::Isolate* isolate)
      : LoopingThread(isolate) { }
  void RunLoop() {
    v8::Locker locker;
    CHECK(i::Isolate::Current() != NULL);
    CHECK_GT(i::Isolate::Current()->thread_manager()->CurrentId(), 0);
    SetV8ThreadId();
    while (IsRunning()) {
      v8::HandleScope scope;
      v8::Persistent<v8::Context> context = v8::Context::New();
      CHECK(!context.IsEmpty());
      {
        v8::Context::Scope context_scope(context);
        SignalRunning();
        CompileRun(
            "var j; for (var i=0; i<10000; ++i) { j = Math.sin(i); }");
      }
      context.Dispose();
      i::OS::Sleep(1);
    }
  }
};


class LoopingNonJsThread : public LoopingThread {
 public:
  explicit LoopingNonJsThread(v8::internal::Isolate* isolate)
      : LoopingThread(isolate) { }
  void RunLoop() {
    v8::Locker locker;
    v8::Unlocker unlocker;
    // Now thread has V8's id, but will not run VM code.
    CHECK(i::Isolate::Current() != NULL);
    CHECK_GT(i::Isolate::Current()->thread_manager()->CurrentId(), 0);
    double i = 10;
    SignalRunning();
    while (IsRunning()) {
      i = sin(i);
      i::OS::Sleep(1);
    }
  }
};


class TestSampler : public v8::internal::Sampler {
 public:
  explicit TestSampler(v8::internal::Isolate* isolate)
      : Sampler(isolate, 0, true, true),
        semaphore_(v8::internal::OS::CreateSemaphore(0)),
        was_sample_stack_called_(false) {
  }

  ~TestSampler() { delete semaphore_; }

  void SampleStack(v8::internal::TickSample*) {
    was_sample_stack_called_ = true;
  }

  void Tick(v8::internal::TickSample*) { semaphore_->Signal(); }

  bool WaitForTick() { return semaphore_->Wait(1000000); }

  void Reset() { was_sample_stack_called_ = false; }

  bool WasSampleStackCalled() { return was_sample_stack_called_; }

 private:
  v8::internal::Semaphore* semaphore_;
  bool was_sample_stack_called_;
};


}  // namespace

TEST(ProfMultipleThreads) {
  TestSampler* sampler = NULL;
  {
    v8::Locker locker;
    sampler = new TestSampler(v8::internal::Isolate::Current());
    sampler->Start();
    CHECK(sampler->IsActive());
  }

  LoopingJsThread jsThread(v8::internal::Isolate::Current());
  jsThread.Start();
  LoopingNonJsThread nonJsThread(v8::internal::Isolate::Current());
  nonJsThread.Start();

  CHECK(!sampler->WasSampleStackCalled());
  jsThread.WaitForRunning();
  jsThread.SendSigProf();
  CHECK(sampler->WaitForTick());
  CHECK(sampler->WasSampleStackCalled());
  sampler->Reset();
  CHECK(!sampler->WasSampleStackCalled());
  nonJsThread.WaitForRunning();
  nonJsThread.SendSigProf();
  CHECK(!sampler->WaitForTick());
  CHECK(!sampler->WasSampleStackCalled());
  sampler->Stop();

  jsThread.Stop();
  nonJsThread.Stop();
  jsThread.Join();
  nonJsThread.Join();

  delete sampler;
}

#endif  // __linux__


// Test for issue http://crbug.com/23768 in Chromium.
// Heap can contain scripts with already disposed external sources.
// We need to verify that LogCompiledFunctions doesn't crash on them.
namespace {

class SimpleExternalString : public v8::String::ExternalStringResource {
 public:
  explicit SimpleExternalString(const char* source)
      : utf_source_(StrLength(source)) {
    for (int i = 0; i < utf_source_.length(); ++i)
      utf_source_[i] = source[i];
  }
  virtual ~SimpleExternalString() {}
  virtual size_t length() const { return utf_source_.length(); }
  virtual const uint16_t* data() const { return utf_source_.start(); }
 private:
  i::ScopedVector<uint16_t> utf_source_;
};

}  // namespace

TEST(Issue23768) {
  v8::HandleScope scope;
  v8::Handle<v8::Context> env = v8::Context::New();
  env->Enter();

  SimpleExternalString source_ext_str("(function ext() {})();");
  v8::Local<v8::String> source = v8::String::NewExternal(&source_ext_str);
  // Script needs to have a name in order to trigger InitLineEnds execution.
  v8::Handle<v8::String> origin = v8::String::New("issue-23768-test");
  v8::Handle<v8::Script> evil_script = v8::Script::Compile(source, origin);
  CHECK(!evil_script.IsEmpty());
  CHECK(!evil_script->Run().IsEmpty());
  i::Handle<i::ExternalTwoByteString> i_source(
      i::ExternalTwoByteString::cast(*v8::Utils::OpenHandle(*source)));
  // This situation can happen if source was an external string disposed
  // by its owner.
  i_source->set_resource(NULL);

  // Must not crash.
  LOGGER->LogCompiledFunctions();
}


static v8::Handle<v8::Value> ObjMethod1(const v8::Arguments& args) {
  return v8::Handle<v8::Value>();
}

TEST(LogCallbacks) {
  ScopedLoggerInitializer initialize_logger(false);

  v8::Persistent<v8::FunctionTemplate> obj =
      v8::Persistent<v8::FunctionTemplate>::New(v8::Isolate::GetCurrent(),
                                                v8::FunctionTemplate::New());
  obj->SetClassName(v8_str("Obj"));
  v8::Handle<v8::ObjectTemplate> proto = obj->PrototypeTemplate();
  v8::Local<v8::Signature> signature = v8::Signature::New(obj);
  proto->Set(v8_str("method1"),
             v8::FunctionTemplate::New(ObjMethod1,
                                       v8::Handle<v8::Value>(),
                                       signature),
             static_cast<v8::PropertyAttribute>(v8::DontDelete));

  initialize_logger.env()->Global()->Set(v8_str("Obj"), obj->GetFunction());
  CompileRun("Obj.prototype.method1.toString();");

  LOGGER->LogCompiledFunctions();

  bool exists = false;
  i::Vector<const char> log(
      i::ReadFile(initialize_logger.StopLoggingGetTempFile(), &exists, true));
  CHECK(exists);

  i::EmbeddedVector<char, 100> ref_data;
  i::OS::SNPrintF(ref_data,
                  "code-creation,Callback,-3,0x%" V8PRIxPTR ",1,\"method1\"\0",
                  ObjMethod1);

  CHECK_NE(NULL, StrNStr(log.start(), ref_data.start(), log.length()));

  obj.Dispose(v8::Isolate::GetCurrent());
}


static v8::Handle<v8::Value> Prop1Getter(v8::Local<v8::String> property,
                                         const v8::AccessorInfo& info) {
  return v8::Handle<v8::Value>();
}

static void Prop1Setter(v8::Local<v8::String> property,
                                         v8::Local<v8::Value> value,
                                         const v8::AccessorInfo& info) {
}

static v8::Handle<v8::Value> Prop2Getter(v8::Local<v8::String> property,
                                         const v8::AccessorInfo& info) {
  return v8::Handle<v8::Value>();
}

TEST(LogAccessorCallbacks) {
  ScopedLoggerInitializer initialize_logger(false);

  v8::Persistent<v8::FunctionTemplate> obj =
      v8::Persistent<v8::FunctionTemplate>::New(v8::Isolate::GetCurrent(),
                                                v8::FunctionTemplate::New());
  obj->SetClassName(v8_str("Obj"));
  v8::Handle<v8::ObjectTemplate> inst = obj->InstanceTemplate();
  inst->SetAccessor(v8_str("prop1"), Prop1Getter, Prop1Setter);
  inst->SetAccessor(v8_str("prop2"), Prop2Getter);

  LOGGER->LogAccessorCallbacks();

  bool exists = false;
  i::Vector<const char> log(
      i::ReadFile(initialize_logger.StopLoggingGetTempFile(), &exists, true));
  CHECK(exists);

  EmbeddedVector<char, 100> prop1_getter_record;
  i::OS::SNPrintF(prop1_getter_record,
                  "code-creation,Callback,-3,0x%" V8PRIxPTR ",1,\"get prop1\"",
                  Prop1Getter);
  CHECK_NE(NULL,
           StrNStr(log.start(), prop1_getter_record.start(), log.length()));

  EmbeddedVector<char, 100> prop1_setter_record;
  i::OS::SNPrintF(prop1_setter_record,
                  "code-creation,Callback,-3,0x%" V8PRIxPTR ",1,\"set prop1\"",
                  Prop1Setter);
  CHECK_NE(NULL,
           StrNStr(log.start(), prop1_setter_record.start(), log.length()));

  EmbeddedVector<char, 100> prop2_getter_record;
  i::OS::SNPrintF(prop2_getter_record,
                  "code-creation,Callback,-3,0x%" V8PRIxPTR ",1,\"get prop2\"",
                  Prop2Getter);
  CHECK_NE(NULL,
           StrNStr(log.start(), prop2_getter_record.start(), log.length()));

  obj.Dispose(v8::Isolate::GetCurrent());
}


TEST(IsLoggingPreserved) {
  ScopedLoggerInitializer initialize_logger(false);

  CHECK(LOGGER->is_logging());
  LOGGER->ResumeProfiler();
  CHECK(LOGGER->is_logging());
  LOGGER->PauseProfiler();
  CHECK(LOGGER->is_logging());
}


typedef i::NativesCollection<i::TEST> TestSources;


// Test that logging of code create / move events is equivalent to traversal of
// a resulting heap.
TEST(EquivalenceOfLoggingAndTraversal) {
  // This test needs to be run on a "clean" V8 to ensure that snapshot log
  // is loaded. This is always true when running using tools/test.py because
  // it launches a new cctest instance for every test. To be sure that launching
  // cctest manually also works, please be sure that no tests below
  // are using V8.
  //
  // P.S. No, V8 can't be re-initialized after disposal, see include/v8.h.
  CHECK(!i::V8::IsRunning());

  // Start with profiling to capture all code events from the beginning.
  ScopedLoggerInitializer initialize_logger(false);

  // Compile and run a function that creates other functions.
  CompileRun(
      "(function f(obj) {\n"
      "  obj.test =\n"
      "    (function a(j) { return function b() { return j; } })(100);\n"
      "})(this);");
  v8::V8::PauseProfiler();
  HEAP->CollectAllGarbage(i::Heap::kMakeHeapIterableMask);
  LOGGER->StringEvent("test-logging-done", "");

  // Iterate heap to find compiled functions, will write to log.
  LOGGER->LogCompiledFunctions();
  LOGGER->StringEvent("test-traversal-done", "");

  bool exists = false;
  i::Vector<const char> log(
      i::ReadFile(initialize_logger.StopLoggingGetTempFile(), &exists, true));
  CHECK(exists);
  v8::Handle<v8::String> log_str = v8::String::New(log.start(), log.length());
  initialize_logger.env()->Global()->Set(v8_str("_log"), log_str);

  i::Vector<const unsigned char> source = TestSources::GetScriptsSource();
  v8::Handle<v8::String> source_str = v8::String::New(
      reinterpret_cast<const char*>(source.start()), source.length());
  v8::TryCatch try_catch;
  v8::Handle<v8::Script> script = v8::Script::Compile(source_str, v8_str(""));
  if (script.IsEmpty()) {
    v8::String::Utf8Value exception(try_catch.Exception());
    printf("compile: %s\n", *exception);
    CHECK(false);
  }
  v8::Handle<v8::Value> result = script->Run();
  if (result.IsEmpty()) {
    v8::String::Utf8Value exception(try_catch.Exception());
    printf("run: %s\n", *exception);
    CHECK(false);
  }
  // The result either be a "true" literal or problem description.
  if (!result->IsTrue()) {
    v8::Local<v8::String> s = result->ToString();
    i::ScopedVector<char> data(s->Length() + 1);
    CHECK_NE(NULL, data.start());
    s->WriteAscii(data.start());
    printf("%s\n", data.start());
    // Make sure that our output is written prior crash due to CHECK failure.
    fflush(stdout);
    CHECK(false);
  }
}
