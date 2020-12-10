;================================================================================
;   STOPWATCH
;================================================================================
Class Stopwatch {

  __New() {
    DllCall("QueryPerformanceFrequency", "Int64*", freq)
    this.freq := freq
    DllCall("QueryPerformanceCounter", "Int64*", epoch)
    this.epoch := epoch
    Return this
  }

  Milliseconds() {
    DllCall("QueryPerformanceCounter", "Int64*", now)
    this.now := now
    Return Round((this.now - this.epoch) / this.freq * 1000)
  }
  
}