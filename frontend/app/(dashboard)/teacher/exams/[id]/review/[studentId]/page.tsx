'use client'

import { useState } from 'react'
import { ChevronLeft, ChevronDown, ChevronUp, HelpCircle, PenLine, CheckSquare2, BookOpen, Sparkles, Pencil, Loader2 } from 'lucide-react'
import Link from 'next/link'
import { useParams } from 'next/navigation'
import useSWR from 'swr'
import { AvatarCircle } from '@/components/fastcheck/avatar-circle'
import { TeacherOverrideDialog } from '@/components/fastcheck/teacher-override-dialog'
import { cn } from '@/lib/utils'
import { api, type QuestionResponse } from '@/lib/api-client'
import { getInitials } from '@/lib/exam-status'

export default function StudentDetailPage() {
  const params = useParams()
  const studentId = params.studentId as string
  const examId = params.id as string

  const { data: examData, error, isLoading, mutate } = useSWR(`examStatus-${examId}`, () => api.getTeacherExamStatus(parseInt(examId)))

  const [expandedQuestions, setExpandedQuestions] = useState<Set<number>>(new Set())
  const [overrideQuestion, setOverrideQuestion] = useState<QuestionResponse | null>(null)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <Loader2 className="w-8 h-8 text-[#2D5BFF] animate-spin" />
      </div>
    )
  }

  if (error || !examData) {
    return <div className="text-red-500">Detaylar yüklenemedi.</div>
  }

  const cluster = examData.studentClusters.find(c => c.studentId.toString() === studentId)
  if (!cluster) {
    return <div className="text-red-500">Öğrenci bulunamadı.</div>
  }

  const questions = cluster.questions || []

  const toggleQuestion = (id: number) => {
    setExpandedQuestions((prev) => {
      const next = new Set(prev)
      if (next.has(id)) {
        next.delete(id)
      } else {
        next.add(id)
      }
      return next
    })
  }

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link
          href={`/teacher/exams/${examId}/review`}
          className="w-9 h-9 bg-white rounded-xl flex items-center justify-center shadow-sm hover:bg-[#F0F2F8] transition-colors"
        >
          <ChevronLeft size={18} className="text-[#6B7280]" />
        </Link>
        <h1 className="text-xl font-semibold text-[#111827]">Soru Detayları</h1>
      </div>

      {/* Student Header Card */}
      <div className="bg-white rounded-2xl shadow-sm p-5 flex items-center gap-4">
        <AvatarCircle initials={getInitials(cluster.studentName)} size="lg" />
        <div className="flex-1">
          <p className="font-semibold text-[#111827] text-lg">{cluster.studentName}</p>
          <p className="text-sm text-[#1DB8A4]">{cluster.matchingStatus === 'CONFIRMED' ? 'Eşleşti' : 'Otomatik Eşleşti'}</p>
        </div>
        <div className="text-right">
          <p className="text-3xl font-bold text-[#1DB8A4]">%{Math.round(cluster.scorePercentage || 0)}</p>
          <p className="text-sm text-[#9CA3AF]">{cluster.awardedPoints}/{cluster.maxPoints} puan</p>
        </div>
      </div>

      {/* Questions Accordion */}
      <div className="space-y-3">
        {questions.map((question) => {
          const isExpanded = expandedQuestions.has(question.id)
          return (
            <div key={question.id} className="bg-white rounded-2xl shadow-sm overflow-hidden">
              {/* Question Header */}
              <div
                onClick={() => toggleQuestion(question.id)}
                className="w-full flex items-center gap-3 p-4 hover:bg-[#F9FAFB] transition-colors cursor-pointer"
                role="button"
                tabIndex={0}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    toggleQuestion(question.id);
                  }
                }}
              >
                <div className="w-8 h-8 bg-[#E8EDFF] rounded-full flex items-center justify-center text-sm font-bold text-[#2D5BFF] shrink-0">
                  {question.questionOrder}
                </div>
                <div className="flex-1 text-left">
                  <p className="font-semibold text-[#111827] text-sm">Soru {question.questionOrder}</p>
                  <p className="text-xs text-[#9CA3AF]">Sayfa {question.pageNumber} &bull; {question.questionType}</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm font-bold text-[#1DB8A4]">{question.awardedPoints} / {question.maxPoints} puan</span>
                  <span className="text-xs text-[#9CA3AF]">&bull; {question.gradingStatus}</span>
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      setOverrideQuestion(question)
                    }}
                    className="w-7 h-7 rounded-lg bg-[#E8EDFF] flex items-center justify-center text-[#2D5BFF] hover:bg-[#2D5BFF] hover:text-white transition-colors ml-1"
                    title="Puanı Düzenle"
                  >
                    <Pencil size={12} />
                  </button>
                </div>
                {isExpanded ? (
                  <ChevronUp size={16} className="text-[#9CA3AF] shrink-0" />
                ) : (
                  <ChevronDown size={16} className="text-[#9CA3AF] shrink-0" />
                )}
              </div>

              {/* Expanded Content */}
              {isExpanded && (
                <div className="px-4 pb-4 space-y-3 border-t border-[#F0F2F8] pt-3">
                  {/* Soru Metni */}
                  <div className="bg-[#F0F2F8] rounded-xl p-3">
                    <div className="flex items-center gap-2 mb-2">
                      <HelpCircle size={14} className="text-[#6B7280]" />
                      <span className="text-xs font-medium text-[#6B7280]">Soru Metni</span>
                    </div>
                    <p className="text-sm text-[#111827] leading-relaxed">{question.questionText}</p>
                  </div>

                  {/* Öğrenci Cevabı */}
                  <div className="bg-[#F0F2F8] rounded-xl p-3">
                    <div className="flex items-center gap-2 mb-2">
                      <PenLine size={14} className="text-[#6B7280]" />
                      <span className="text-xs font-medium text-[#6B7280]">Öğrenci Cevabı</span>
                    </div>
                    <p className="text-sm text-[#111827] leading-relaxed">{question.studentAnswer}</p>
                  </div>

                  {/* Beklenen Cevap */}
                  <div className="bg-[#F0F2F8] rounded-xl p-3">
                    <div className="flex items-center gap-2 mb-2">
                      <CheckSquare2 size={14} className="text-[#6B7280]" />
                      <span className="text-xs font-medium text-[#6B7280]">Beklenen Cevap</span>
                    </div>
                    <p className="text-sm text-[#111827] leading-relaxed">{question.expectedAnswer}</p>
                  </div>

                  {/* Rubrik */}
                  <div className="bg-[#F0F2F8] rounded-xl p-3">
                    <div className="flex items-center gap-2 mb-2">
                      <BookOpen size={14} className="text-[#6B7280]" />
                      <span className="text-xs font-medium text-[#6B7280]">Rubrik</span>
                    </div>
                    <p className="text-sm text-[#111827] leading-relaxed">{question.gradingRubric || '-'}</p>
                  </div>

                  {/* Değerlendirme Özeti */}
                  <div className="bg-[#F0F2F8] rounded-xl p-3">
                    <div className="flex items-center gap-2 mb-2">
                      <Sparkles size={14} className="text-[#6B7280]" />
                      <span className="text-xs font-medium text-[#6B7280]">Degerlendirme Ozeti</span>
                    </div>
                    <p className="text-sm text-[#111827] leading-relaxed">{question.evaluationSummary}</p>
                  </div>

                  {/* Güven Skorları */}
                  <div className="bg-[#F0F2F8] rounded-xl p-3">
                    <p className="text-xs font-medium text-[#6B7280] mb-3">Guven Skorlari</p>
                    <div className="space-y-3">
                      <div>
                        <div className="flex items-center justify-between mb-1.5">
                          <span className="text-sm text-[#374151]">OCR/Tanıma guveni</span>
                          <span className="text-sm font-semibold text-[#22C55E]">%{Math.round(question.confidence * 100)}</span>
                        </div>
                        <div className="h-1.5 bg-[#E5E7EB] rounded-full overflow-hidden">
                          <div
                            className="h-full bg-[#22C55E] rounded-full"
                            style={{ width: `${Math.round(question.confidence * 100)}%` }}
                          />
                        </div>
                      </div>
                      <div>
                        <div className="flex items-center justify-between mb-1.5">
                          <span className="text-sm text-[#374151]">Puanlama guveni</span>
                          <span className="text-sm font-semibold text-[#22C55E]">%{Math.round((question.gradingConfidence || 0) * 100)}</span>
                        </div>
                        <div className="h-1.5 bg-[#E5E7EB] rounded-full overflow-hidden">
                          <div
                            className="h-full bg-[#22C55E] rounded-full"
                            style={{ width: `${Math.round((question.gradingConfidence || 0) * 100)}%` }}
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )
        })}
      </div>

      {/* Override Dialog */}
      {overrideQuestion && (
        <TeacherOverrideDialog
          open={!!overrideQuestion}
          onOpenChange={(open) => !open && setOverrideQuestion(null)}
          questionText={overrideQuestion.questionText || ''}
          maxScore={overrideQuestion.maxScore || 0}
          currentScore={overrideQuestion.awardedPoints || 0}
          expectedAnswer={overrideQuestion.expectedAnswer || ''}
          rubric={overrideQuestion.gradingRubric || ''}
          onSave={async (awardedPoints, expectedAnswer, rubric) => {
            await api.updateQuestionOverride(parseInt(examId), overrideQuestion.id, {
              awardedPoints,
              maxPoints: overrideQuestion.maxScore || 0,
              expectedAnswer,
              gradingRubric: rubric
            })
            mutate()
            setOverrideQuestion(null)
          }}
        />
      )}
    </div>
  )
}
