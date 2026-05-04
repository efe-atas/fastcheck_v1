'use client'

import { useState, useRef, useEffect } from 'react'
import { FileText, Loader2, CheckCircle2, Camera, ImageIcon, ChevronDown, RefreshCw } from 'lucide-react'
import { StatusBadge } from '@/components/fastcheck/status-badge'
import useSWR from 'swr'
import { api, type OcrJobStatusResponse } from '@/lib/api-client'
import { cn } from '@/lib/utils'

export default function OcrLabPage() {
  const [selectedExam, setSelectedExam] = useState<string>('')
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [isUploading, setIsUploading] = useState(false)

  const { data: dashboard, error, isLoading, mutate } = useSWR('teacherDashboard', api.getTeacherDashboard)

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!selectedExam) {
      alert('Lütfen önce bir sınav seçin.')
      return
    }
    if (!e.target.files || e.target.files.length === 0) return
    setIsUploading(true)
    try {
      const formData = new FormData()
      Array.from(e.target.files).forEach(f => formData.append('images', f))
      await api.uploadExamImages(parseInt(selectedExam), formData)
      mutate() // Refresh the jobs list
      alert('Yükleme başarılı. İşlem devam ediyor.')
    } catch (err) {
      alert('Yükleme başarısız oldu.')
    } finally {
      setIsUploading(false)
      if (fileInputRef.current) fileInputRef.current.value = ''
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <Loader2 className="w-8 h-8 text-[#2D5BFF] animate-spin" />
      </div>
    )
  }

  if (error || !dashboard) {
    return <div className="text-red-500">Bilgiler yüklenemedi.</div>
  }

  const exams = dashboard.latestExams || []
  const jobs = dashboard.recentOcrJobs || []
  
  useEffect(() => {
    if (!selectedExam && dashboard?.latestExams?.length > 0) {
      setSelectedExam(dashboard.latestExams[0].examId.toString())
    }
  }, [selectedExam, dashboard?.latestExams])

  const totalJobs = jobs.length
  const activeJobs = jobs.filter(j => j.status === 'PROCESSING' || j.status === 'PENDING').length
  const completedJobs = jobs.filter(j => j.status === 'COMPLETED').length

  return (
    <div className="space-y-6">
      {/* Header */}
      <h1 className="text-2xl font-semibold text-[#111827]">OCR Lab</h1>

      {/* Stat Cards */}
      <div className="grid grid-cols-3 gap-5">
        <div className="bg-white rounded-2xl shadow-sm p-5">
          <FileText size={20} className="text-[#6B7280] mb-3" />
          <p className="text-3xl font-semibold text-[#111827]">{totalJobs}</p>
          <p className="text-[13px] text-[#6B7280] mt-1">Toplam İş</p>
        </div>
        <div className="bg-white rounded-2xl shadow-sm p-5">
          <Loader2 size={20} className="text-[#1DB8A4] mb-3" />
          <p className="text-3xl font-semibold text-[#111827]">{activeJobs}</p>
          <p className="text-[13px] text-[#6B7280] mt-1">Devam Eden</p>
        </div>
        <div className="bg-white rounded-2xl shadow-sm p-5">
          <CheckCircle2 size={20} className="text-[#22C55E] mb-3" />
          <p className="text-3xl font-semibold text-[#111827]">{completedJobs}</p>
          <p className="text-[13px] text-[#6B7280] mt-1">Tamamlanan</p>
        </div>
      </div>

      {/* Upload Card */}
      <div className="bg-white rounded-2xl shadow-sm p-5">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-[#E8EDFF] rounded-xl flex items-center justify-center">
            <Camera size={20} className="text-[#2D5BFF]" />
          </div>
          <div>
            <p className="font-semibold text-[#111827]">Yeni tarama başlat</p>
            <p className="text-sm text-[#6B7280]">
              Kamera veya galeriden kağıt ekleyin. Tamamlanan kayıtlar otomatik olarak geçmişe düşer.
            </p>
          </div>
        </div>

        {/* Exam Selector */}
        <div className="relative mb-4">
          <div className="flex items-center gap-2 bg-[#F0F2F8] border border-[#E5E7EB] rounded-xl px-4 py-3 cursor-pointer">
            <FileText size={16} className="text-[#6B7280]" />
            <span className="flex-1 text-sm font-medium text-[#111827]">
              {exams.find((e) => e.examId.toString() === selectedExam)?.title ?? 'Sınav Seç'}
            </span>
            <ChevronDown size={16} className="text-[#6B7280]" />
          </div>
          <select
            value={selectedExam}
            onChange={(e) => setSelectedExam(e.target.value)}
            className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
          >
            {exams.map((exam) => (
              <option key={exam.examId} value={exam.examId.toString()}>
                {exam.title}
              </option>
            ))}
          </select>
        </div>

        {/* Upload Buttons */}
        <div className="grid grid-cols-2 gap-3">
          <button
            disabled
            title="Kamera yalnızca mobil uygulamada kullanılabilir"
            className="flex items-center justify-center gap-2 bg-[#2D5BFF] text-white py-3 rounded-xl text-sm font-semibold opacity-50 cursor-not-allowed"
          >
            <Camera size={16} />
            Kamera
          </button>
          <button
            onClick={() => fileInputRef.current?.click()}
            disabled={isUploading || !selectedExam}
            className="flex items-center justify-center gap-2 bg-[#E8EDFF] text-[#2D5BFF] py-3 rounded-xl text-sm font-semibold hover:bg-[#D1DCFF] transition-colors disabled:opacity-50"
          >
            {isUploading ? <Loader2 size={16} className="animate-spin" /> : <ImageIcon size={16} />}
            {isUploading ? 'Yükleniyor...' : 'Galeri'}
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            multiple
            className="hidden"
            onChange={handleUpload}
          />
        </div>
      </div>

      {/* Active Jobs */}
      <section>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-base font-semibold text-[#111827]">Aktif İşlem</h2>
          <button className="text-sm text-[#2D5BFF] font-medium flex items-center gap-1 hover:text-[#1A3FCC]">
            <RefreshCw size={13} />
            Yenile
          </button>
        </div>

        {activeJobs === 0 ? (
          <div className="bg-white rounded-2xl shadow-sm p-8 text-center">
            <p className="text-[#9CA3AF] text-sm">Aktif işlem yok</p>
          </div>
        ) : (
          <div className="space-y-3">
            {jobs.filter(j => j.status === 'PROCESSING' || j.status === 'PENDING').map((job) => (
              <OcrJobCard key={job.jobId} job={job} isActive />
            ))}
          </div>
        )}
      </section>

      {/* Processing History */}
      <section>
        <h2 className="text-base font-semibold text-[#111827] mb-4">İşlem Geçmişi</h2>
        <div className="space-y-3">
          {jobs.filter(j => j.status !== 'PROCESSING' && j.status !== 'PENDING').map((job) => (
            <OcrJobCard key={job.jobId} job={job} isActive={false} />
          ))}
          {jobs.filter(j => j.status !== 'PROCESSING' && j.status !== 'PENDING').length === 0 && (
             <p className="text-[#9CA3AF] text-sm py-4">Geçmiş işlem bulunmuyor.</p>
          )}
        </div>
      </section>
    </div>
  )
}

function OcrJobCard({
  job,
  isActive,
}: {
  job: OcrJobStatusResponse
  isActive: boolean
}) {
  return (
    <div className={cn('bg-white rounded-2xl shadow-sm p-4', isActive && 'border border-[#E5E7EB]')}>
      <div className="flex items-center gap-3">
        <div className="w-12 h-12 bg-[#F0F2F8] rounded-xl flex items-center justify-center shrink-0">
          <FileText size={20} className="text-[#9CA3AF]" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between gap-2">
            <p className="font-semibold text-[#111827] text-sm truncate">Job: {job.jobId.substring(0, 8)}</p>
            <span className={cn(
              'px-2.5 py-0.5 rounded-full text-xs font-semibold shrink-0',
              job.status === 'COMPLETED' ? 'bg-[#D1FAE5] text-[#059669]' :
              job.status === 'FAILED' ? 'bg-[#FEE2E2] text-[#DC2626]' :
              'bg-[#FEF3C7] text-[#D97706]'
            )}>
              {job.status === 'COMPLETED' ? 'Tamamlandı' : job.status === 'FAILED' ? 'Hata' : 'İşleniyor'}
            </span>
          </div>
          <p className="text-xs text-[#9CA3AF] mt-0.5">
             {new Date(job.createdAt).toLocaleString('tr-TR')}
          </p>
          <div className="mt-2">
            {isActive && (
              <div className="h-1.5 bg-[#E5E7EB] rounded-full overflow-hidden">
                <div
                  className="h-full bg-[#D97706] rounded-full transition-all animate-pulse"
                  style={{ width: `50%` }}
                />
              </div>
            )}
            {job.errorMessage && (
              <p className="text-xs text-[#DC2626] mt-1">{job.errorMessage}</p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
