// Copyright 2013 the V8 project authors. All rights reserved.
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

#ifndef V8_MARKING_THREAD_H_
#define V8_MARKING_THREAD_H_

#include "atomicops.h"
#include "flags.h"
#include "platform.h"
#include "v8utils.h"

#include "spaces.h"

#include "heap.h"

namespace v8 {
namespace internal {

class MarkingThread : public Thread {
 public:
  explicit MarkingThread(Isolate* isolate);

  void Run();
  void Stop();
  void StartMarking();
  void WaitForMarkingThread();

  ~MarkingThread() {
    delete start_marking_semaphore_;
    delete end_marking_semaphore_;
    delete stop_semaphore_;
  }

 private:
  Isolate* isolate_;
  Heap* heap_;
  Semaphore* start_marking_semaphore_;
  Semaphore* end_marking_semaphore_;
  Semaphore* stop_semaphore_;
  volatile AtomicWord stop_thread_;
  int id_;
  static Atomic32 id_counter_;
};

} }  // namespace v8::internal

#endif  // V8_MARKING_THREAD_H_
