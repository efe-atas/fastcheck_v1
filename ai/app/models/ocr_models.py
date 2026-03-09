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


class UnmatchedTextBlock(BaseModel):
    raw_text: str
    confidence: float = Field(ge=0, le=1)


class PageItem(BaseModel):
    page_number: int
    questions: List[QuestionItem]
    unmatched_text_blocks: List[UnmatchedTextBlock]


class ExamPaperOutput(BaseModel):
    document_type: str = "exam_paper"
    language: str = "tr"
    pages: List[PageItem]


class OcrExtractResponse(BaseModel):
    request_id: str
    result: ExamPaperOutput
