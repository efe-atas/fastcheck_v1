from typing import List
from pydantic import BaseModel, Field, HttpUrl


class OcrExtractRequest(BaseModel):
    image_url: HttpUrl
    source_id: str | None = None
    language_hint: str = "tr"


class QuestionItem(BaseModel):
    question_id: str
    question_text_raw: str
    question_lines: List[str]
    student_answer_raw: str
    student_answer_lines: List[str]
    confidence: float = Field(ge=0, le=1)
    question_type: str = "unknown"
    expected_answer_raw: str = ""
    grading_rubric_raw: str = ""
    max_points: float = Field(default=1, ge=0)
    awarded_points: float = Field(default=0, ge=0)
    grading_confidence: float = Field(default=0, ge=0, le=1)
    evaluation_summary: str = ""
    needs_review: bool = False
    is_correct: bool | None = None


class UnmatchedTextBlock(BaseModel):
    raw_text: str
    confidence: float = Field(ge=0, le=1)


class PageItem(BaseModel):
    page_number: int
    detected_student_name: str = ""
    name_confidence: float = Field(default=0, ge=0, le=1)
    questions: List[QuestionItem]
    unmatched_text_blocks: List[UnmatchedTextBlock]


class ExamPaperOutput(BaseModel):
    document_type: str = "exam_paper"
    language: str = "tr"
    grading_system_summary: str = ""
    total_max_points: float = Field(default=0, ge=0)
    pages: List[PageItem]


class OcrExtractResponse(BaseModel):
    request_id: str
    result: ExamPaperOutput
