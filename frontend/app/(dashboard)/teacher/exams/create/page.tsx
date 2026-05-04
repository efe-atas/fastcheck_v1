'use client'

import { useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { Suspense } from 'react'
import { ChevronLeft, Plus, Trash2, Check, GripVertical, Loader2 } from 'lucide-react'
import Link from 'next/link'
import useSWR from 'swr'
import { api, type CreateExamRequest } from '@/lib/api-client'
import { cn } from '@/lib/utils'

type Step = 1 | 2 | 3

interface Question {
  id: string
  points: string
  expectedAnswer: string
  rubric: string
  expanded: boolean
}

function CreateExamContent() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const initialClassId = searchParams.get('classId')

  const [step, setStep] = useState<Step>(initialClassId ? 2 : 1)
  const [selectedClass, setSelectedClass] = useState<string | null>(initialClassId)
  const [examName, setExamName] = useState('')
  const [examDate, setExamDate] = useState('')
  const [totalPoints, setTotalPoints] = useState('')
  const [description, setDescription] = useState('')
  const [questions, setQuestions] = useState<Question[]>([
    { id: '1', points: '10', expectedAnswer: '', rubric: '', expanded: false },
  ])
  const [isSubmitting, setIsSubmitting] = useState(false)

  const { data: classes, isLoading: isClassesLoading } = useSWR('teacherClasses', api.listTeacherClasses)

  const steps = [
    { number: 1, label: 'Sınıf Seç' },
    { number: 2, label: 'Sınav Bilgileri' },
    { number: 3, label: 'Sorular' },
  ]

  const addQuestion = () => {
    setQuestions((prev) => [
      ...prev,
      { id: String(Date.now()), points: '10', expectedAnswer: '', rubric: '', expanded: false },
    ])
  }

  const removeQuestion = (id: string) => {
    setQuestions((prev) => prev.filter((q) => q.id !== id))
  }

  const toggleQuestion = (id: string) => {
    setQuestions((prev) =>
      prev.map((q) => (q.id === id ? { ...q, expanded: !q.expanded } : q))
    )
  }

  return (
    <div className="space-y-6 max-w-2xl mx-auto">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link
          href="/teacher/exams"
          className="w-9 h-9 bg-white rounded-xl flex items-center justify-center shadow-sm hover:bg-[#F0F2F8] transition-colors"
        >
          <ChevronLeft size={18} className="text-[#6B7280]" />
        </Link>
        <h1 className="text-xl font-semibold text-[#111827]">Yeni Sınav Oluştur</h1>
      </div>

      {/* Step Indicator */}
      <div className="flex items-center gap-0">
        {steps.map((s, idx) => {
          const isActive = step === s.number
          const isDone = step > s.number
          return (
            <div key={s.number} className="flex items-center flex-1 last:flex-none">
              <div className="flex flex-col items-center gap-1.5">
                <div
                  className={cn(
                    'w-8 h-8 rounded-full flex items-center justify-center text-sm font-semibold transition-colors',
                    isDone
                      ? 'bg-[#0BBFB0] text-white'
                      : isActive
                      ? 'bg-[#3B4FD8] text-white'
                      : 'bg-[#E5E7EB] text-[#9CA3AF]'
                  )}
                >
                  {isDone ? <Check size={14} /> : s.number}
                </div>
                <span
                  className={cn(
                    'text-xs font-medium whitespace-nowrap',
                    isActive ? 'text-[#3B4FD8]' : isDone ? 'text-[#0BBFB0]' : 'text-[#9CA3AF]'
                  )}
                >
                  {s.label}
                </span>
              </div>
              {idx < steps.length - 1 && (
                <div
                  className={cn(
                    'flex-1 h-0.5 mb-5 mx-2 transition-colors',
                    isDone ? 'bg-[#0BBFB0]' : 'bg-[#E5E7EB]'
                  )}
                />
              )}
            </div>
          )
        })}
      </div>

      {/* Step Content */}
      {step === 1 && (
        <div className="space-y-4">
          <h2 className="text-base font-semibold text-[#111827]">Sınıf Seçin</h2>
          {isClassesLoading ? (
            <div className="flex items-center justify-center py-10">
              <Loader2 className="w-6 h-6 text-[#3B4FD8] animate-spin" />
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-3">
              {(classes || []).map((cls) => {
                const isSelected = selectedClass === cls.classId.toString()
                return (
                  <button
                    key={cls.classId}
                    onClick={() => setSelectedClass(cls.classId.toString())}
                  className={cn(
                    'bg-white rounded-2xl shadow-sm p-5 text-left relative hover:shadow-md transition-all border-2',
                    isSelected ? 'border-[#3B4FD8]' : 'border-[#DDE3F0]'
                  )}
                >
                    {isSelected && (
                      <div className="absolute top-3 right-3 w-5 h-5 bg-[#3B4FD8] rounded-full flex items-center justify-center">
                        <Check size={12} className="text-white" />
                      </div>
                    )}
                    <p className="text-base font-semibold text-[#111827]">{cls.className}</p>
                    <p className="text-sm text-[#6B7280] mt-0.5">Sınıf ID: {cls.classId}</p>
                    <div className="mt-3">
                      <span className="text-xs font-medium text-[#6B7280] bg-[#F3F4F6] rounded-full px-2.5 py-1">
                        {cls.examCount} sınav
                      </span>
                    </div>
                  </button>
                )
              })}
            </div>
          )}
          <div className="flex justify-end pt-2">
            <button
              onClick={() => selectedClass && setStep(2)}
              disabled={!selectedClass}
              className={cn(
                'px-6 py-2.5 rounded-xl text-sm font-semibold transition-colors',
                selectedClass
                  ? 'bg-[#3B4FD8] text-white hover:bg-[#2D3DB8]'
                  : 'bg-[#E5E7EB] text-[#9CA3AF] cursor-not-allowed'
              )}
            >
              Devam Et
            </button>
          </div>
        </div>
      )}

      {step === 2 && (
        <div className="space-y-5">
          <h2 className="text-base font-semibold text-[#111827]">Sınav Bilgileri</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-[#374151] mb-1.5">Sınav Adı</label>
              <input
                type="text"
                value={examName}
                onChange={(e) => setExamName(e.target.value)}
                placeholder="Örn: TYT Matematik Deneme 1"
                className="w-full bg-white border border-[#DDE3F0] rounded-xl px-4 py-3 text-sm text-[#111827] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#3B4FD8] focus:ring-1 focus:ring-[#3B4FD8]"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-[#374151] mb-1.5">Sınav Tarihi</label>
              <input
                type="date"
                value={examDate}
                onChange={(e) => setExamDate(e.target.value)}
                className="w-full bg-white border border-[#DDE3F0] rounded-xl px-4 py-3 text-sm text-[#111827] focus:outline-none focus:border-[#3B4FD8] focus:ring-1 focus:ring-[#3B4FD8]"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-[#374151] mb-1.5">Toplam Puan</label>
              <input
                type="number"
                value={totalPoints}
                onChange={(e) => setTotalPoints(e.target.value)}
                placeholder="100"
                className="w-full bg-white border border-[#DDE3F0] rounded-xl px-4 py-3 text-sm text-[#111827] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#3B4FD8] focus:ring-1 focus:ring-[#3B4FD8]"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-[#374151] mb-1.5">
                Açıklama <span className="text-[#9CA3AF] font-normal">(isteğe bağlı)</span>
              </label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Sınav hakkında kısa bir açıklama..."
                rows={3}
                className="w-full bg-white border border-[#DDE3F0] rounded-xl px-4 py-3 text-sm text-[#111827] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#3B4FD8] focus:ring-1 focus:ring-[#3B4FD8] resize-none"
              />
            </div>
          </div>
          <div className="flex items-center justify-between pt-2">
            <button
              onClick={() => setStep(1)}
              className="px-6 py-2.5 rounded-xl border border-[#E5E7EB] text-sm font-semibold text-[#6B7280] hover:bg-[#F0F2F8] transition-colors"
            >
              Geri
            </button>
            <button
              onClick={() => examName && setStep(3)}
              disabled={!examName}
              className={cn(
                'px-6 py-2.5 rounded-xl text-sm font-semibold transition-colors',
                examName
                  ? 'bg-[#3B4FD8] text-white hover:bg-[#2D3DB8]'
                  : 'bg-[#E5E7EB] text-[#9CA3AF] cursor-not-allowed'
              )}
            >
              Devam Et
            </button>
          </div>
        </div>
      )}

      {step === 3 && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-base font-semibold text-[#111827]">Sorular</h2>
            <button
              onClick={addQuestion}
              className="flex items-center gap-1.5 text-sm font-semibold text-[#3B4FD8] hover:text-[#2D3DB8] transition-colors"
            >
              <Plus size={16} />
              Soru Ekle
            </button>
          </div>
          <div className="space-y-3">
            {questions.map((q, idx) => (
              <div key={q.id} className="bg-white rounded-2xl shadow-sm overflow-hidden">
                <div className="flex items-center gap-3 p-4">
                  <GripVertical size={16} className="text-[#9CA3AF] cursor-grab" />
                  <div className="w-7 h-7 bg-[#E5EAFE] rounded-full flex items-center justify-center text-xs font-semibold text-[#3B4FD8]">
                    {idx + 1}
                  </div>
                  <span className="flex-1 text-sm font-semibold text-[#111827]">Soru {idx + 1}</span>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      value={q.points}
                      onChange={(e) =>
                        setQuestions((prev) =>
                          prev.map((item) =>
                            item.id === q.id ? { ...item, points: e.target.value } : item
                          )
                        )
                      }
                      className="w-16 bg-[#F8FAFC] border border-[#DDE3F0] rounded-lg px-2 py-1.5 text-sm text-center text-[#111827] focus:outline-none focus:border-[#3B4FD8]"
                    />
                    <span className="text-xs text-[#9CA3AF]">puan</span>
                  </div>
                  <button
                    onClick={() => toggleQuestion(q.id)}
                    className="text-xs text-[#3B4FD8] font-medium px-2"
                  >
                    {q.expanded ? 'Kapat' : 'Genişlet'}
                  </button>
                  {questions.length > 1 && (
                    <button
                      onClick={() => removeQuestion(q.id)}
                      className="w-7 h-7 rounded-lg flex items-center justify-center text-[#9CA3AF] hover:text-[#B91C1C] hover:bg-[#FEF2F2] transition-colors"
                    >
                      <Trash2 size={14} />
                    </button>
                  )}
                </div>
                {q.expanded && (
                  <div className="px-4 pb-4 space-y-3 border-t border-[#F0F2F8] pt-3">
                    <div>
                      <label className="block text-xs font-medium text-[#6B7280] mb-1">Beklenen Cevap</label>
                      <textarea
                        value={q.expectedAnswer}
                        onChange={(e) =>
                          setQuestions((prev) =>
                            prev.map((item) =>
                              item.id === q.id ? { ...item, expectedAnswer: e.target.value } : item
                            )
                          )
                        }
                        placeholder="Beklenen cevabı yazın..."
                        rows={2}
                        className="w-full bg-[#F8FAFC] border border-[#DDE3F0] rounded-xl px-3 py-2 text-sm text-[#111827] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#3B4FD8] resize-none"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-[#6B7280] mb-1">Rubrik</label>
                      <textarea
                        value={q.rubric}
                        onChange={(e) =>
                          setQuestions((prev) =>
                            prev.map((item) =>
                              item.id === q.id ? { ...item, rubric: e.target.value } : item
                            )
                          )
                        }
                        placeholder="Puanlama kriterlerini yazın..."
                        rows={2}
                        className="w-full bg-[#F8FAFC] border border-[#DDE3F0] rounded-xl px-3 py-2 text-sm text-[#111827] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#3B4FD8] resize-none"
                      />
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
          <div className="flex items-center justify-between pt-2">
            <button
              onClick={() => setStep(2)}
              className="px-6 py-2.5 rounded-xl border border-[#E5E7EB] text-sm font-semibold text-[#6B7280] hover:bg-[#F0F2F8] transition-colors"
            >
              Geri
            </button>
            <button
              onClick={async () => {
                if (!selectedClass || !examName) return
                try {
                  setIsSubmitting(true)
                  const request: CreateExamRequest = {
                    title: examName + (description ? ` - ${description}` : ''),
                    status: 'DRAFT',
                    questions: questions.map((q, idx) => ({
                      questionOrder: idx + 1,
                      pageNumber: 1, // Defaulting all questions to page 1 for now since UI doesn't collect page info
                      questionType: 'OPEN_ENDED',
                      expectedAnswer: q.expectedAnswer,
                      gradingRubric: q.rubric,
                      maxPoints: parseFloat(q.points) || 0
                    }))
                  }
                  const created = await api.createExam(parseInt(selectedClass), request)
                  router.push(`/teacher/exams/${created.examId}/upload`)
                } catch (err) {
                  alert('Sınav oluşturulurken hata oluştu')
                } finally {
                  setIsSubmitting(false)
                }
              }}
              disabled={isSubmitting}
              className="px-6 py-2.5 rounded-xl bg-[#3B4FD8] text-white text-sm font-semibold hover:bg-[#2D3DB8] transition-colors disabled:opacity-50 flex items-center gap-2"
            >
              {isSubmitting && <Loader2 size={16} className="animate-spin" />}
              {isSubmitting ? 'Oluşturuluyor...' : 'Sınavı Oluştur'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export default function CreateExamPage() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center py-10">
        <Loader2 className="w-8 h-8 text-[#3B4FD8] animate-spin" />
      </div>
    }>
      <CreateExamContent />
    </Suspense>
  )
}
