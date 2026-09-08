/// Outcome of answering a single gate item. See the README's core loop:
/// correct earns the long pass, incorrect earns the short one plus a
/// shortened review interval, and tooFast discards the attempt entirely
/// and re-serves the same item.
enum AnswerResult { correct, incorrect, tooFast }