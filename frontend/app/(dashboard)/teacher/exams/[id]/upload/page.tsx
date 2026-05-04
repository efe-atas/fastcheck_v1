'use client'

import { useRef } from 'react'
import { ChevronLeft, Camera, ImageIcon, RefreshCw, FileText, Loader2, CheckCircle2 } from 'lucide-react'
import Link from 'next/link'
import { useParams } from 'next/navigation'
import useSWR from 'swr'
import { api } from '@/lib/api-client'

export default function ExamUploadPage() {
  const id = useParams().id as string
  const fileInputRef = useRef<HTMLInputElement>(null)
  
  const { data: examData, error, isLoading, mutate } = useSWR(`examStatus-${id}`, () => api.getTeacherExamStatus(parseInt(id)))
  const [isUploading, setIsUploading] = useState(false)

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return
    setIsUploading(true)
    try {
      const formData = new FormData()
      Array.from(e.target.files).forEach(f => formData.append('images', f))
      await api.uploadExamImages(parseInt(id), formData)
      mutate() // Refresh the jobs list
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

  if (error || !examData) {
    return <div className="text-red-500">Sınav bilgileri yüklenemedi.</div>
  }

  const jobs = examData.ocrJobs || []
  const totalJobs = jobs.length
  const completedJobs = jobs.filter(j => j.status === 'COMPLETED').length
  const processingJobs = jobs.filter(j => j.status === 'PROCESSING' || j.status === 'PENDING').length

  return (
    <div className="space-y-6 max-w-2xl">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link
          href={`/teacher/exams/${id}/review`}
          className="w-9 h-9 bg-white rounded-xl flex items-center justify-center shadow-sm hover:bg-[#F0F2F8] transition-colors"
        >
          <ChevronLeft size={18} className="text-[#6B7280]" />
        </Link>
        <div>
          <h1 className="text-xl font-semibold text-[#111827]">OCR Lab</h1>
          <p className="text-sm text-[#6B7280]">{examData.title}</p>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-3 gap-4">
        <div className="bg-white rounded-2xl shadow-sm p-4">
          <FileText size={18} className="text-[#6B7280] mb-2" />
          <p className="text-2xl font-semibold text-[#111827]">{totalJobs}</p>
          <p className="text-[12px] text-[#6B7280] mt-0.5">Toplam İş</p>
        </div>
        <div className="bg-white rounded-2xl shadow-sm p-4">
          <Loader2 size={18} className="text-[#1DB8A4] mb-2" />
          <p className="text-2xl font-semibold text-[#111827]">{processingJobs}</p>
          <p className="text-[12px] text-[#6B7280] mt-0.5">Devam Eden</p>
        </div>
        <div className="bg-white rounded-2xl shadow-sm p-4">
          <CheckCircle2 size={18} className="text-[#22C55E] mb-2" />
          <p className="text-2xl font-semibold text-[#111827]">{completedJobs}</p>
          <p className="text-[12px] text-[#6B7280] mt-0.5">Tamamlanan</p>
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
              Kamera veya galeriden kağıt ekleyin.
            </p>
          </div>
        </div>
        <div className="bg-[#F0F2F8] rounded-xl px-4 py-3 mb-4 flex items-center gap-2">
          <FileText size={16} className="text-[#6B7280]" />
          <span className="text-sm font-medium text-[#111827]">{examData.title} &bull; Sınıf ID: {examData.classId}</span>
        </div>
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
            disabled={isUploading}
            className="flex items-center justify-center gap-2 bg-[#E8EDFF] text-[#2D5BFF] py-3 rounded-xl text-sm font-semibold hover:bg-[#D1DCFF] transition-colors disabled:opacity-50"
          >
            {isUploading ? <Loader2 size={16} className="animate-spin" /> : <ImageIcon size={16} />}
            {isUploading ? 'Yükleniyor...' : 'Galeri'}
          </button>
          <input ref={fileInputRef} type="file" accept="image/*" multiple className="hidden" onChange={handleUpload} />
        </div>
      </div>

      {/* History */}
      <section>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-base font-semibold text-[#111827]">İşlem Geçmişi</h2>
          <button className="text-sm text-[#2D5BFF] font-medium flex items-center gap-1">
            <RefreshCw size={13} />
            Yenile
          </button>
        </div>
        <div className="space-y-3">
          {jobs.map((job) => (
            <div key={job.jobId} className="bg-white rounded-2xl shadow-sm p-4 border border-[#E5E7EB]">
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
                  <p className="text-xs text-[#9CA3AF] mt-0.5">{new Date(job.createdAt).toLocaleString('tr-TR')}</p>
                  {job.status === 'PROCESSING' && (
                    <div className="mt-2 h-1.5 bg-[#E5E7EB] rounded-full overflow-hidden">
                      <div className="h-full bg-[#D97706] rounded-full animate-pulse" style={{ width: `50%` }} />
                    </div>
                  )}
                  {job.errorMessage && (
                    <p className="text-xs text-[#DC2626] mt-1">{job.errorMessage}</p>
                  )}
                </div>
              </div>
            </div>
          ))}
          {jobs.length === 0 && (
            <p className="text-sm text-[#6B7280] text-center py-4">Henüz işleme alınan kağıt yok.</p>
          )}
        </div>
      </section>
    </div>
  )
}
