'use client'

import { useState } from 'react'
import { Save } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { cn } from '@/lib/utils'

interface TeacherOverrideDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  questionText: string
  maxScore: number
  currentScore: number
  expectedAnswer: string
  rubric: string
  onSave?: (score: number, expectedAnswer: string, rubric: string) => Promise<void>
}

type ResultType = 'Dogru' | 'Yanlış' | 'Kısmi / Belirsiz'

export function TeacherOverrideDialog({
  open,
  onOpenChange,
  questionText,
  maxScore,
  currentScore,
  expectedAnswer,
  rubric,
  onSave,
}: TeacherOverrideDialogProps) {
  const [score, setScore] = useState(currentScore.toString())
  const [result, setResult] = useState<ResultType>('Dogru')
  const [teacherNote, setTeacherNote] = useState('')
  const [isSaving, setIsSaving] = useState(false)

  const resultOptions: ResultType[] = ['Dogru', 'Yanlış', 'Kısmi / Belirsiz']

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md bg-[#F0F2F8] border-none shadow-xl p-0 rounded-2xl overflow-hidden">
        <DialogHeader className="px-6 pt-6 pb-4">
          <DialogTitle className="text-lg font-semibold text-[#111827]">
            Öğretmen Override
          </DialogTitle>
          <p className="text-sm text-[#6B7280] mt-1 font-normal leading-relaxed">
            {questionText}
          </p>
        </DialogHeader>

        <div className="px-6 pb-6 space-y-4">
          {/* Score Inputs */}
          <div className="grid grid-cols-2 gap-3">
            <div className="relative">
              <label className="absolute -top-2 left-3 bg-white px-1 text-xs text-[#6B7280]">
                Verilen Puan
              </label>
              <input
                type="number"
                value={score}
                onChange={(e) => setScore(e.target.value)}
                className="w-full bg-white border border-[#E5E7EB] rounded-xl px-4 py-3 text-[#111827] font-medium focus:outline-none focus:border-[#2D5BFF] focus:ring-1 focus:ring-[#2D5BFF]"
              />
            </div>
            <div className="relative">
              <label className="absolute -top-2 left-3 bg-white px-1 text-xs text-[#6B7280]">
                Maksimum Puan
              </label>
              <input
                type="number"
                value={maxScore}
                readOnly
                className="w-full bg-white border border-[#E5E7EB] rounded-xl px-4 py-3 text-[#111827] font-medium focus:outline-none cursor-default"
              />
            </div>
          </div>

          {/* Result Segmented Control */}
          <div>
            <p className="text-sm text-[#6B7280] mb-2">Sonuc</p>
            <div className="flex items-center gap-0 bg-white border border-[#E5E7EB] rounded-full p-1">
              {resultOptions.map((option) => (
                <button
                  key={option}
                  onClick={() => setResult(option)}
                  className={cn(
                    'flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-full text-sm font-medium transition-colors',
                    result === option
                      ? 'bg-[#2D5BFF] text-white'
                      : 'text-[#6B7280] hover:text-[#111827]'
                  )}
                >
                  {option === 'Dogru' && result === 'Dogru' && (
                    <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                    </svg>
                  )}
                  {option}
                </button>
              ))}
            </div>
          </div>

          {/* Read-only fields */}
          <div className="relative">
            <label className="absolute -top-2 left-3 bg-[#F0F2F8] px-1 text-xs text-[#6B7280]">
              Beklenen Cevap
            </label>
            <textarea
              readOnly
              value={expectedAnswer}
              rows={3}
              className="w-full bg-white border border-[#E5E7EB] rounded-xl px-4 pt-3 pb-3 text-[#111827] text-sm focus:outline-none cursor-default resize-none"
            />
          </div>

          <div className="relative">
            <label className="absolute -top-2 left-3 bg-[#F0F2F8] px-1 text-xs text-[#6B7280]">
              Rubrik
            </label>
            <textarea
              readOnly
              value={rubric}
              rows={2}
              className="w-full bg-white border border-[#E5E7EB] rounded-xl px-4 pt-3 pb-3 text-[#111827] text-sm focus:outline-none cursor-default resize-none"
            />
          </div>

          <div className="relative">
            <label className="absolute -top-2 left-3 bg-[#F0F2F8] px-1 text-xs text-[#6B7280]">
              Öğretmen Notu
            </label>
            <textarea
              value={teacherNote}
              onChange={(e) => setTeacherNote(e.target.value)}
              placeholder="Notunuzu buraya yazın..."
              rows={3}
              className="w-full bg-white border border-[#E5E7EB] rounded-xl px-4 pt-3 pb-3 text-[#111827] text-sm focus:outline-none focus:border-[#2D5BFF] focus:ring-1 focus:ring-[#2D5BFF] resize-none"
            />
          </div>

          {/* Action Buttons */}
          <div className="grid grid-cols-2 gap-3 pt-1">
            <button
              onClick={() => onOpenChange(false)}
              disabled={isSaving}
              className="py-3 rounded-xl border border-[#E5E7EB] bg-white text-[#6B7280] font-semibold text-sm hover:bg-[#F3F4F6] transition-colors disabled:opacity-50"
            >
              Vazgeç
            </button>
            <button
              onClick={async () => {
                if (onSave) {
                  setIsSaving(true)
                  try {
                    await onSave(parseFloat(score) || 0, expectedAnswer, rubric + (teacherNote ? `\nNot: ${teacherNote}` : ''))
                  } finally {
                    setIsSaving(false)
                  }
                } else {
                  onOpenChange(false)
                }
              }}
              disabled={isSaving}
              className="py-3 rounded-xl bg-[#2D5BFF] text-white font-semibold text-sm flex items-center justify-center gap-2 hover:bg-[#1A3FCC] transition-colors disabled:opacity-50"
            >
              {isSaving ? (
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <Save size={16} />
              )}
              {isSaving ? 'Kaydediliyor...' : 'Kaydet'}
            </button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
