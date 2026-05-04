'use client'

import { useState } from 'react'
import Link from 'next/link'
import {
  FileText,
  Clock,
  CheckCircle,
  ChevronRight,
  BookOpen,
  TrendingUp,
  AlertCircle,
  Loader2,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { getStatusConfig, formatDate, isCompleted } from '@/lib/exam-status'
import useSWR from 'swr'
import { api } from '@/lib/api-client'

const today = new Date()
const dateStr = today.toLocaleDateString('tr-TR', {
  weekday: 'long',
  day: 'numeric',
  month: 'long',
  year: 'numeric',
})

function capitalize(str: string) {
  return str.charAt(0).toUpperCase() + str.slice(1)
}

function getHeroSubtitle(
  readyExams: number,
  processingExams: number,
  totalExams: number,
) {
  if (totalExams === 0) return 'Öğretmenin ilk sınavı eklediğinde burası otomatik dolacak'
  if (processingExams > 0) return 'İşlenen sınavlar tamamlandıkça aşağıdaki liste güncellenecek'
  return 'Hazır olan sınavları aşağıdaki listeden hemen açabilirsin'
}

const filters: { key: ExamStatusCode | null; label: string }[] = [
  { key: null, label: 'Tümü' },
  { key: 'READY', label: 'Hazır' },
  { key: 'PROCESSING', label: 'İşleniyor' },
  { key: 'DRAFT', label: 'Taslak' },
  { key: 'FAILED', label: 'Hata' },
]

export default function StudentDashboardPage() {
  const { data: summary, error, isLoading } = useSWR('studentDashboard', api.getStudentDashboard)
  const [activeFilter, setActiveFilter] = useState<string | null>(null)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <Loader2 className="w-8 h-8 text-[#2D5BFF] animate-spin" />
      </div>
    )
  }

  if (error || !summary) {
    return <div className="text-red-500">Gösterge paneli yüklenemedi.</div>
  }

  const filtered = activeFilter
    ? summary.latestExams.filter((e) => e.status === activeFilter)
    : summary.latestExams

  const recentReady = summary.latestExams.filter((e) => isCompleted(e.status)).slice(0, 3)

  return (
    <div className="space-y-6">
      {/* Greeting Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-[#111827]">
            Merhaba, Öğrenci 👋
          </h1>
          <p className="text-[#6B7280] text-sm mt-1">{capitalize(dateStr)}</p>
        </div>
        <span className="inline-flex items-center rounded-full bg-[#1DB8A4] px-4 py-1.5 text-xs font-medium text-white tracking-wider">
          ÖĞRENCİ
        </span>
      </div>

      {/* Hero Banner */}
      <div
        className="w-full rounded-2xl overflow-hidden relative"
        style={{
          background: 'linear-gradient(135deg, #2D5BFF 0%, #1C2D9D 100%)',
          minHeight: 140,
        }}
      >
        <div className="absolute inset-0 opacity-10">
          <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <pattern id="grid-s" width="40" height="40" patternUnits="userSpaceOnUse">
                <path d="M 40 0 L 0 0 0 40" fill="none" stroke="white" strokeWidth="1" />
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#grid-s)" />
          </svg>
        </div>
        <div className="relative p-6">
          <p className="text-white font-bold text-base">
            {summary.readyExams} sınav hazır bekliyor
          </p>
          <p className="text-white/70 text-sm mt-1">
            {getHeroSubtitle(summary.readyExams, summary.processingExams, summary.totalExams)}
          </p>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-3 gap-5">
        <div className="bg-white rounded-2xl shadow-sm p-5 border border-[#E5E7EB]">
          <FileText size={20} className="text-[#2D5BFF] mb-3" />
          <p className="text-3xl font-semibold text-[#111827]">{summary.totalExams}</p>
          <p className="text-[13px] text-[#6B7280] mt-1">Toplam Sınav</p>
        </div>
        <div className="bg-white rounded-2xl shadow-sm p-5 border border-[#E5E7EB]">
          <Clock size={20} className="text-[#F59E0B] mb-3" />
          <div className="flex items-center gap-2">
            <p className="text-3xl font-semibold text-[#111827]">{summary.processingExams}</p>
            {summary.processingExams > 0 && (
              <span className="w-2 h-2 rounded-full bg-[#1DB8A4] mb-1" />
            )}
          </div>
          <p className="text-[13px] text-[#6B7280] mt-1">İşlenenler</p>
        </div>
        <div className="bg-white rounded-2xl shadow-sm p-5 border border-[#E5E7EB]">
          <CheckCircle size={20} className="text-[#1DB8A4] mb-3" />
          <p className="text-3xl font-semibold text-[#111827]">{summary.readyExams}</p>
          <p className="text-[13px] text-[#6B7280] mt-1">Hazır Sınav</p>
        </div>
      </div>

      {/* Recent Ready Exams */}
      <section>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-base font-semibold text-[#111827]">Son Hazır Sınavlar</h2>
          <Link
            href="/student/exams"
            className="text-[14px] text-[#1DB8A4] font-medium flex items-center gap-1"
          >
            Tümü <ChevronRight size={14} />
          </Link>
        </div>
        <div className="space-y-3">
          {recentReady.length === 0 ? (
            <div className="text-center py-10">
              <BookOpen size={32} className="text-[#9CA3AF] mx-auto mb-2" />
              <p className="text-[#9CA3AF] text-sm">Henüz hazır sınav bulunmuyor</p>
            </div>
          ) : (
            recentReady.map((exam) => {
              const cfg = getStatusConfig(exam.status)
              return (
                <Link
                  key={exam.examId}
                  href={`/student/exams/${exam.examId}`}
                  className="block"
                >
                  <div className="bg-white rounded-2xl shadow-sm border-l-4 border-l-[#1DB8A4] p-4 hover:shadow-md transition-shadow">
                    <div className="flex items-center justify-between gap-3">
                      <div className="flex-1 min-w-0">
                        <h3 className="text-base font-semibold text-[#111827] truncate">{exam.title}</h3>
                        <div className="flex items-center gap-2 mt-1">
                          <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium', cfg.bg, cfg.text)}>
                            {cfg.label}
                          </span>
                          <span className="text-[13px] text-[#9CA3AF]">{formatDate(exam.createdAt)}</span>
                          {exam.scorePercentage != null && (
                            <span className="text-[13px] font-medium text-[#2D5BFF] ml-auto">
                              %{Math.round(exam.scorePercentage)}
                            </span>
                          )}
                        </div>
                      </div>
                      <span className="text-[#9CA3AF]">›</span>
                    </div>
                  </div>
                </Link>
              )
            })
          )}
        </div>
      </section>

      {/* All Exams with Filter */}
      <section>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-base font-semibold text-[#111827]">Sınav Listesi</h2>
          <span className="text-sm text-[#6B7280]">Duruma göre filtrele</span>
        </div>

        {/* Filter chips */}
        <div className="flex gap-2 flex-wrap mb-4">
          {filters.map((f) => (
            <button
              key={String(f.key)}
              onClick={() => setActiveFilter(f.key)}
              className={cn(
                'px-4 py-2 rounded-full text-sm font-semibold transition-colors border',
                activeFilter === f.key
                  ? 'bg-[#2D5BFF] text-white border-[#2D5BFF]'
                  : 'bg-white text-[#6B7280] border-[#E5E7EB] hover:border-[#2D5BFF] hover:text-[#2D5BFF]',
              )}
            >
              {f.label}
            </button>
          ))}
        </div>

        <div className="space-y-3">
          {filtered.length === 0 ? (
            <div className="text-center py-12 bg-white rounded-2xl">
              <TrendingUp size={32} className="text-[#9CA3AF] mx-auto mb-2" />
              <p className="text-[#9CA3AF] text-sm">Bu filtrede sınav bulunmuyor</p>
            </div>
          ) : (
            filtered.map((exam) => {
              const cfg = getStatusConfig(exam.status)
              const isClickable = isCompleted(exam.status)
              const content = (
                <div
                  className={cn(
                    'bg-white rounded-2xl shadow-sm p-4 border-l-4 transition-shadow',
                    isClickable
                      ? 'border-l-[#2D5BFF] hover:shadow-md cursor-pointer'
                      : 'border-l-[#E5E7EB] opacity-80',
                  )}
                >
                  <div className="flex items-center gap-4">
                    {/* Icon */}
                    <div
                      className={cn(
                        'w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-gradient-to-br',
                        cfg.iconGradient,
                      )}
                    >
                      {exam.status === 'READY' ? (
                        <CheckCircle size={22} className="text-white" />
                      ) : exam.status === 'PROCESSING' ? (
                        <Clock size={22} className="text-white" />
                      ) : exam.status === 'FAILED' ? (
                        <AlertCircle size={22} className="text-white" />
                      ) : (
                        <FileText size={22} className="text-white" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="text-base font-semibold text-[#111827] truncate">{exam.title}</h3>
                      <div className="flex items-center gap-2 mt-1">
                        <span
                          className={cn(
                            'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',
                            cfg.bg,
                            cfg.text,
                          )}
                        >
                          {cfg.label}
                        </span>
                        <span className="text-[12px] text-[#9CA3AF]">{formatDate(exam.createdAt)}</span>
                      </div>
                      {exam.scorePercentage != null && isCompleted(exam.status) && (
                        <div className="mt-2">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-[12px] text-[#6B7280]">Puan</span>
                            <span className="text-[12px] font-semibold text-[#111827]">
                              {exam.awardedPoints} / {exam.maxPoints}
                            </span>
                          </div>
                          <div className="h-1.5 bg-[#F3F4F6] rounded-full overflow-hidden">
                            <div
                              className="h-full bg-[#2D5BFF] rounded-full"
                              style={{ width: `${exam.scorePercentage}%` }}
                            />
                          </div>
                        </div>
                      )}
                    </div>
                    {isClickable && (
                      <ChevronRight size={18} className="text-[#9CA3AF] shrink-0" />
                    )}
                  </div>
                </div>
              )

              return isClickable ? (
                <Link key={exam.examId} href={`/student/exams/${exam.examId}`} className="block">
                  {content}
                </Link>
              ) : (
                <div key={exam.examId}>{content}</div>
              )
            })
          )}
        </div>
      </section>
    </div>
  )
}
