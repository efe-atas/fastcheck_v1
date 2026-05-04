'use client'

import { Building2, Clock, CheckCircle2, ChevronRight, Loader2, Calendar, AlertCircle, FileText } from 'lucide-react'
import Link from 'next/link'
import useSWR from 'swr'
import { StatusBadge } from '@/components/fastcheck/status-badge'
import { api } from '@/lib/api-client'
import { getStatusConfig, formatDate } from '@/lib/exam-status'
import { cn } from '@/lib/utils'

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

export default function TeacherDashboard() {
  const { data: dashboard, error, isLoading } = useSWR('teacherDashboard', api.getTeacherDashboard)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <Loader2 className="w-8 h-8 text-[#3B4FD8] animate-spin" />
      </div>
    )
  }

  if (error || !dashboard) {
    return <div className="text-red-500">Gösterge paneli yüklenemedi.</div>
  }

  // Mobil: latestExams listesinin ilk 3'ü gösteriliyor
  const upcomingExams = (dashboard.latestExams || []).slice(0, 3)
  const recentOcrJobs = (dashboard.recentOcrJobs || []).slice(0, 5)

  return (
    <div className="space-y-6">
      {/* Greeting — mobilin _DashboardHero başlığıyla aynı */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-[#111827]">
            Merhaba, Öğretmen 👋
          </h1>
          <p className="text-[#6B7280] text-sm mt-1">{capitalize(dateStr)}</p>
        </div>
        <span className="inline-flex items-center rounded-full bg-[#0BBFB0]/20 px-4 py-1.5 text-xs font-bold text-[#0BBFB0] tracking-wider">
          ÖĞRETMEN
        </span>
      </div>

      {/* Hero Banner */}
      <div
        className="w-full rounded-2xl overflow-hidden relative"
        style={{ background: 'linear-gradient(135deg, #3B4FD8 0%, #1A2A9E 100%)', minHeight: 140 }}
      >
        <div className="absolute inset-0 opacity-10">
          <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
                <path d="M 40 0 L 0 0 0 40" fill="none" stroke="white" strokeWidth="1"/>
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#grid)" />
          </svg>
        </div>
        <div className="relative p-6">
          <h2 className="text-white font-bold text-base">FastCheck AI ile</h2>
          <p className="text-white/80 text-sm mt-1">Kağıtları saniyeler içinde dijitalleştir</p>
          <Link
            href="/teacher/ocr"
            className="mt-4 inline-flex items-center gap-2 bg-white/20 hover:bg-white/30 text-white text-sm font-medium px-4 py-2 rounded-xl transition-colors"
          >
            OCR Lab&apos;ı Aç <ChevronRight size={16} />
          </Link>
        </div>
      </div>

      {/* Stat Cards — mobilin 3 metric kartı: Aktif Sınıflar | Bekleyen OCR | Tamamlanan Sınavlar */}
      <div className="grid grid-cols-3 gap-4">
        <div className="bg-white rounded-2xl shadow-sm p-5 border border-[#D9DFF2]">
          <Building2 size={18} className="text-[#5068F3] mb-3" />
          <p className="text-3xl font-bold text-[#0F1729]">{dashboard.totalClasses}</p>
          <p className="text-[11px] text-[#6B7A99] mt-1">Aktif Sınıflar</p>
        </div>
        <div className="bg-white rounded-2xl shadow-sm p-5 border border-[#D9DFF2]">
          <Clock size={18} className="text-[#5068F3] mb-3" />
          <div className="flex items-center gap-1.5">
            <p className="text-3xl font-bold text-[#0F1729]">{dashboard.processingExams}</p>
            {dashboard.processingExams > 0 && (
              <span className="w-2 h-2 rounded-full bg-[#0BBFB0] mb-1" />
            )}
          </div>
          <p className="text-[11px] text-[#6B7A99] mt-1">Bekleyen OCR</p>
        </div>
        {/* Mobil: 3. metrik = readyValue = readyExams — "Bu Hafta Sınavlar" etiketi */}
        <div className="bg-white rounded-2xl shadow-sm p-5 border border-[#D9DFF2]">
          <Calendar size={18} className="text-[#5068F3] mb-3" />
          <p className="text-3xl font-bold text-[#0F1729]">{dashboard.readyExams}</p>
          <p className="text-[11px] text-[#6B7A99] mt-1">Bu Hafta Sınavlar</p>
        </div>
      </div>

      {/* Upcoming Exams — mobilin _UpcomingExamTile widget'ı */}
      <section>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-[15px] font-bold text-[#0F1729]">Yaklaşan Sınavlar</h2>
          <Link href="/teacher/exams" className="text-[14px] text-[#3B4FD8] font-medium flex items-center gap-1">
            Tümü <ChevronRight size={14} />
          </Link>
        </div>
        <div className="space-y-3">
          {upcomingExams.length === 0 ? (
            <div className="bg-white rounded-2xl border border-[#DDE3F0] p-6 text-center">
              <p className="text-sm text-[#6B7A99]">Henüz planlanmış sınav bulunmuyor.</p>
            </div>
          ) : (
            upcomingExams.map((exam) => {
              const cfg = getStatusConfig(exam.status)
              const iconColor = cfg.isDone ? '#0BBFB0' : '#3B4FD8'
              return (
                <Link key={exam.examId} href={`/teacher/exams/${exam.examId}/review`} className="block">
                  <div className="bg-white rounded-2xl border border-[#DDE3F0] shadow-sm p-4 hover:shadow-md transition-shadow">
                    <div className="flex items-center gap-3">
                      {/* Icon box */}
                      <div
                        className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
                        style={{ backgroundColor: `${iconColor}1A` }}
                      >
                        {cfg.isDone ? (
                          <CheckCircle2 size={20} style={{ color: iconColor }} />
                        ) : exam.status === 'FAILED' ? (
                          <AlertCircle size={20} style={{ color: iconColor }} />
                        ) : (
                          <FileText size={20} style={{ color: iconColor }} />
                        )}
                      </div>
                      {/* Content */}
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <p className="text-[13px] font-bold text-[#0F1729] truncate">{exam.title}</p>
                          <span className="text-[10px] font-medium text-[#8A96B2] bg-[#E8EDF6] rounded-full px-2 py-0.5 shrink-0">
                            Sınıf #{exam.classId}
                          </span>
                        </div>
                        <div className="flex items-center gap-1.5 text-[#6B7A99]">
                          <Calendar size={11} />
                          <span className="text-[11px]">{formatDate(exam.createdAt)}</span>
                        </div>
                      </div>
                      {/* Status badge */}
                      <span
                        className={cn('text-[10px] font-bold px-2.5 py-1 rounded-full shrink-0', cfg.bg, cfg.text)}
                      >
                        {cfg.label}
                      </span>
                    </div>
                  </div>
                </Link>
              )
            })
          )}
        </div>
      </section>

      {/* Recent OCR — mobilin Son OCR İşlemleri bölümü */}
      <section>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-[15px] font-bold text-[#0F1729]">Son OCR İşlemleri</h2>
          <Link href="/teacher/ocr" className="text-[14px] text-[#3B4FD8] font-medium flex items-center gap-1">
            Tümü <ChevronRight size={14} />
          </Link>
        </div>
        <div className="flex gap-4 overflow-x-auto pb-2">
          {recentOcrJobs.length === 0 ? (
            <p className="text-sm text-[#6B7A99]">Yakın zamanda OCR işlemi yapılmamış.</p>
          ) : (
            recentOcrJobs.map((job) => (
              <div key={job.jobId} className="bg-white rounded-2xl shadow-sm p-3 shrink-0 w-44 border border-[#DDE3F0]">
                <div className="relative">
                  <div className="w-full h-24 bg-[#E5EAFE] rounded-xl flex items-center justify-center">
                    <Clock className="text-[#3B4FD8] w-8 h-8 opacity-50" />
                  </div>
                  <StatusBadge
                    status={job.status}
                    className="absolute top-1.5 right-1.5 text-[10px] px-2 py-0.5"
                  />
                </div>
                <p className="text-xs font-medium text-[#0F1729] mt-2 truncate">İşlem #{job.jobId.slice(0, 6)}</p>
                <p className="text-[11px] text-[#6B7A99] truncate">{new Date(job.createdAt).toLocaleString('tr-TR')}</p>
              </div>
            ))
          )}
        </div>
      </section>
    </div>
  )
}
