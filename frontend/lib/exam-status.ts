// Backend'den gelebilecek tüm sınav durumları
// Mobil uygulamayla birebir uyumlu (teacher_exams_page.dart _statusLabel)
export type ExamStatusCode =
  | 'READY'
  | 'COMPLETED'
  | 'DONE'
  | 'PROCESSING'
  | 'DRAFT'
  | 'PENDING'
  | 'FAILED'
  | string

export interface StatusConfig {
  label: string
  bg: string
  text: string
  color: string   // hex — icon ve badge rengi
  dotColor: string
  iconGradient: string
  isDone: boolean
  isActive: boolean
  isDraft: boolean
}

/**
 * Mobil uygulamadaki _mapExamStatus() ve _statusLabel() fonksiyonlarının
 * web karşılığı. Backend'den gelen ham status string'ini alır.
 */
export function getStatusConfig(status: string): StatusConfig {
  const s = (status ?? '').toUpperCase()

  if (s === 'READY' || s === 'COMPLETED' || s === 'DONE') {
    return {
      label: 'Tamamlandı',
      bg: 'bg-[#E1F5F2]',
      text: 'text-[#0D7A6A]',
      color: '#0BBFB0',
      dotColor: '#1DB8A4',
      iconGradient: 'from-[#1DB8A4] to-[#0D7A6A]',
      isDone: true,
      isActive: false,
      isDraft: false,
    }
  }

  if (s === 'PROCESSING') {
    return {
      label: 'İşleniyor',
      bg: 'bg-[#FFFBEB]',
      text: 'text-[#B45309]',
      color: '#F59E0B',
      dotColor: '#F59E0B',
      iconGradient: 'from-[#F59E0B] to-[#D97706]',
      isDone: false,
      isActive: true,
      isDraft: false,
    }
  }

  if (s === 'FAILED') {
    return {
      label: 'Hata',
      bg: 'bg-[#FEF2F2]',
      text: 'text-[#B91C1C]',
      color: '#EF4444',
      dotColor: '#EF4444',
      iconGradient: 'from-[#EF4444] to-[#B91C1C]',
      isDone: false,
      isActive: true,
      isDraft: false,
    }
  }

  // DRAFT, PENDING ve diğerleri → Taslak / Aktif değil
  return {
    label: s === 'DRAFT' || s === 'PENDING' ? 'Taslak' : s,
    bg: 'bg-[#F3F4F6]',
    text: 'text-[#6B7280]',
    color: '#9CA3AF',
    dotColor: '#9CA3AF',
    iconGradient: 'from-[#9CA3AF] to-[#6B7280]',
    isDone: false,
    isActive: false,
    isDraft: true,
  }
}

/** Mobilden: READY/DONE/COMPLETED = tamamlandı */
export function isCompleted(status: string): boolean {
  const s = (status ?? '').toUpperCase()
  return s === 'READY' || s === 'DONE' || s === 'COMPLETED'
}

/** Mobilden: DRAFT/PENDING = taslak */
export function isDraft(status: string): boolean {
  const s = (status ?? '').toUpperCase()
  return s === 'DRAFT' || s === 'PENDING'
}

/** Aktif = tamamlanmamış ve taslak olmayan (PROCESSING, FAILED vb.) */
export function isActive(status: string): boolean {
  return !isCompleted(status) && !isDraft(status)
}

export function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  return date.toLocaleDateString('tr-TR', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

export function getConfidenceColor(confidence: number): string {
  if (confidence >= 0.8) return '#1DB8A4'
  if (confidence >= 0.5) return '#F59E0B'
  return '#EF4444'
}

export function getInitials(name: string): string {
  const parts = name.trim().split(' ').filter(Boolean)
  if (parts.length >= 2) {
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
  }
  return name.substring(0, Math.min(2, name.length)).toUpperCase()
}

export function formatQuestionType(type: string): string {
  switch (type.toUpperCase()) {
    case 'MULTIPLE_CHOICE': return 'Çoktan seçmeli'
    case 'SHORT_TEXT': return 'Kısa cevap'
    case 'NUMERIC': return 'Sayısal'
    case 'OPEN_ENDED': return 'Açık uçlu'
    default: return type
  }
}
