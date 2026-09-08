"""Question generation.

Rules that are not negotiable:
  1. Prompt against the published skill taxonomy, never against a
     specific source question.
  2. Embed every generated item and reject anything too similar to the
     reference set. Models do occasionally reproduce near-verbatim text.
  3. Verify math answer keys programmatically. Generated keys are wrong
     often enough that this is not optional.
  4. Everything lands reviewed=false.

pipeline/reference/ is gitignored. Official practice material stays
local and is used for prompt tuning only.
"""

SIMILARITY_REJECT_THRESHOLD = 0.85


def generate(skill: str, difficulty: int, tier: str, n: int):
    """TODO(M2)."""
    raise NotImplementedError


def too_similar(stem: str) -> bool:
    """TODO(M2): cosine against embedded reference set."""
    raise NotImplementedError


def verify_key(question: dict) -> bool:
    """TODO(M2): solve math items independently, compare to correct_index."""
    raise NotImplementedError
