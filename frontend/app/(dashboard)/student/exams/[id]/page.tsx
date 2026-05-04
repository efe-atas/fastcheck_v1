'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { ArrowLeft, BookOpen, ChevronDown, FileSearch, Loader2 } from 'lucide-react'
import { cn } from '@/lib/utils'
import useSWR from 'swr'
import { api, type QuestionResponse } from '@/lib/api-client'
import { getConfidenceColor, formatQuestionType } from '@/lib/exam-status'

interface PageParams {
  id: string
}

// ─── Question Card ────────────────────────────────────────────────
function QuestionCard({
  question,
  index,
}: {
  question: QuestionResponse
  index: number
}) {
  const [expanded, setExpanded] = useState(false)
  const confidence = question.confidence ?? 0
  const confidencePercent = Math.round(confidence * 100)
  const confColor = getConfidenceColor(confidence)
  const gradingConfidencePercent = question.gradingConfidence
    ? Math.round(question.gradingConfidence * 100)
    : null

  return (
    <div
      className={cn(
        'bg-white rounded-2xl border transition-all',
        expanded ? 'border-[#3B4FD8]/40 shadow-md' : 'border-[#E5E7EB] shadow-sm',
      )}
    >
      {/* Header – always visible */}
      <button
        className="w-full text-left p-4 flex items-center gap-3"
        onClick={() => setExpanded(!expanded)}
      >
        {/* Number badge */}
        <div className="w-9 h-9 rounded-xl bg-[#E5EAFE] flex items-center justify-center shrink-0">
          <span className="text-sm font-bold text-[#3B4FD8]">{index}</span>
        </div>
        <div className="flex-1 min-w-0">
          <p
            className={cn(
              'text-[15px] font-semibold text-[#111827]',
              !expanded && 'truncate',
            )}
          >
            {question.questionText ?? `Soru ${index}`}
          </p>
          {question.maxPoints != null && question.maxPoints > 0 && (
            <p className="text-[12px] text-[#3B4FD8] font-medium mt-0.5">
              {question.awardedPoints ?? 0} / {question.maxPoints} puan
            </p>
          )}
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <span
            className="text-sm font-semibold px-2.5 py-1 rounded-full"
            style={{
              color: confColor,
              backgroundColor: `${confColor}1A`,
            }}
          >
            %{confidencePercent}
          </span>
          <ChevronDown
            size={18}
            className={cn(
              'text-[#9CA3AF] transition-transform duration-200',
              expanded && 'rotate-180',
            )}
          />
        </div>
      </button>

      {/* Expanded content */}
      {expanded && (
        <div className="px-4 pb-4 space-y-4 border-t border-[#F3F4F6] pt-4">
          {/* Student Answer */}
          {question.studentAnswer && (
            <div>
              <p className="text-[12px] font-semibold text-[#9CA3AF] uppercase tracking-wide mb-1.5">
                Öğrenci Cevabı
              </p>
              <div className="bg-[#F0F2F8] rounded-xl p-3">
                <p className="text-[14px] text-[#111827] leading-relaxed">
                  {question.studentAnswer}
                </p>
              </div>
            </div>
          )}

          {/* Expected Answer */}
          {question.expectedAnswer && (
            <div>
              <p className="text-[12px] font-semibold text-[#9CA3AF] uppercase tracking-wide mb-1.5">
                Beklenen Cevap
              </p>
              <div className="bg-[#F0F2F8] rounded-xl p-3">
                <p className="text-[14px] text-[#111827] leading-relaxed">
                  {question.expectedAnswer}
                </p>
              </div>
            </div>
          )}

          {/* Evaluation Summary */}
          {question.evaluationSummary && (
            <div>
              <p className="text-[12px] font-semibold text-[#9CA3AF] uppercase tracking-wide mb-1.5">
                Değerlendirme
              </p>
              <div className="bg-[#F0F2F8] rounded-xl p-3">
                <p className="text-[14px] text-[#111827] leading-relaxed">
                  {question.evaluationSummary}
                </p>
              </div>
            </div>
          )}

          {/* Meta row */}
          <div className="flex flex-wrap gap-4 text-[12px] text-[#6B7280]">
            <span>Sayfa: <strong className="text-[#111827]">{question.pageNumber}</strong></span>
            <span>Sıra: <strong className="text-[#111827]">{question.questionOrder}</strong></span>
            {question.questionType && (
              <span>
                Tür: <strong className="text-[#111827]">{formatQuestionType(question.questionType)}</strong>
              </span>
            )}
            {question.correct != null && (
              <span>
                Sonuç:{' '}
                <strong className={question.correct ? 'text-[#1DB8A4]' : 'text-[#EF4444]'}>
                  {question.correct ? 'Doğru' : 'Yanlış / Kısmi'}
                </strong>
              </span>
            )}
          </div>

          {/* OCR Confidence bar */}
          <div>
            <div className="flex justify-between text-[12px] mb-1.5">
              <span className="text-[#9CA3AF] font-medium">OCR Güven Skoru</span>
              <span className="font-bold" style={{ color: confColor }}>
                %{confidencePercent}
              </span>
            </div>
            <div className="h-2 bg-[#F3F4F6] rounded-full overflow-hidden">
              <div
                className="h-full rounded-full"
                style={{ width: `${confidencePercent}%`, backgroundColor: confColor }}
              />
            </div>
          </div>

          {/* Grading confidence bar */}
          {gradingConfidencePercent != null && (
            <div>
              <div className="flex justify-between text-[12px] mb-1.5">
                <span className="text-[#9CA3AF] font-medium">Puanlama Güveni</span>
                <span
                  className="font-bold"
                  style={{ color: getConfidenceColor((question.gradingConfidence ?? 0)) }}
                >
                  %{gradingConfidencePercent}
                </span>
              </div>
              <div className="h-2 bg-[#F3F4F6] rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full"
                  style={{
                    width: `${gradingConfidencePercent}%`,
                    backgroundColor: getConfidenceColor(question.gradingConfidence ?? 0),
                  }}
                />
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

// ─── Page ────────────────────────────────────────────────────────
export default function StudentExamDetailPage(props: { params: Promise<PageParams> }) {
  const params = React.use(props.params)
  
  const { data: questions, error, isLoading } = useSWR(`studentExamQuestions-${params.id}`, () => api.getStudentExamQuestions(parseInt(params.id)))

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <Loader2 className="w-8 h-8 text-[#3B4FD8] animate-spin" />
      </div>
    )
  }

  if (error || !questions) {
    return <div className="text-red-500">Sorular yüklenemedi.</div>
  }

  const totalAwarded = questions.reduce((s, q) => s + (q.awardedPoints ?? 0), 0)
  const totalMax = questions.reduce((s, q) => s + (q.maxPoints ?? 0), 0)
  const avgConfidence =
    questions.length > 0
      ? questions.reduce((s, q) => s + (q.confidence ?? 0), 0) / questions.length
      : 0

  return (
    <div className="space-y-6">
      {/* Back + Title */}
      <div className="flex items-center gap-3">
        <Link
          href="/student/exams"
          className="w-9 h-9 bg-white rounded-xl flex items-center justify-center shadow-sm border border-[#E5E7EB] hover:bg-[#F0F2F8] transition-colors"
        >
          <ArrowLeft size={16} className="text-[#6B7280]" />
        </Link>
        <div>
          <h1 className="text-xl font-semibold text-[#111827]">Sınav Detayı</h1>
          <p className="text-sm text-[#6B7280]">Sınav #{params.id} – Soru bazlı analiz</p>
        </div>
      </div>

      {/* Summary bar */}
      <div className="bg-[#E5EAFE] rounded-2xl p-4">
        <div className="flex items-center gap-3 mb-3">
          <FileSearch size={18} className="text-[#3B4FD8]" />
          <span className="text-[14px] font-semibold text-[#3B4FD8]">
            Toplam {questions.length} soru
            {totalMax > 0 && ` · ${totalAwarded} / ${totalMax} puan`}
          </span>
        </div>
        <div className="grid grid-cols-3 gap-3">
          {/* Total Questions */}
          <div className="bg-white rounded-xl p-3 text-center">
            <BookOpen size={18} className="text-[#3B4FD8] mx-auto mb-1" />
            <p className="text-xl font-bold text-[#111827]">{questions.length}</p>
            <p className="text-[11px] text-[#6B7280]">Toplam Soru</p>
          </div>
          {/* Average Confidence */}
          <div className="bg-white rounded-xl p-3 text-center">
            <div className="text-lg font-bold mb-1" style={{ color: getConfidenceColor(avgConfidence) }}>
              %{Math.round(avgConfidence * 100)}
            </div>
            <p className="text-[11px] text-[#6B7280]">Ortalama Güven</p>
          </div>
          {/* Score */}
          {totalMax > 0 && (
            <div className="bg-white rounded-xl p-3 text-center">
              <p className="text-xl font-bold text-[#3B4FD8]">
                {totalAwarded}/{totalMax}
              </p>
              <p className="text-[11px] text-[#6B7280]">Toplam Puan</p>
            </div>
          )}
        </div>
      </div>

      {/* Question cards */}
      <div className="space-y-3">
        {questions.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-2xl border border-[#E5E7EB]">
            <BookOpen size={36} className="text-[#9CA3AF] mx-auto mb-3" />
            <p className="text-[#111827] font-medium">Henüz soru bulunmuyor</p>
            <p className="text-[#6B7280] text-sm mt-1">
              Bu sınava ait sorular henüz işlenmemiş olabilir.
            </p>
          </div>
        ) : (
          questions.map((q, i) => (
            <QuestionCard key={q.id} question={q} index={i + 1} />
          ))
        )}
      </div>
    </div>
  )
}
