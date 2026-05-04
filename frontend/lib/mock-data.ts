export const mockUser = {
  id: '1',
  name: 'Ayşe Yılmaz',
  email: 'ayse@example.com',
  role: 'teacher' as const,
  initials: 'AY',
}

export const mockClasses = [
  { id: '1', name: '12-A Sayısal', school: 'Atatürk Anadolu Lisesi', studentCount: 28 },
  { id: '2', name: '11-B Sözel', school: 'Atatürk Anadolu Lisesi', studentCount: 32 },
  { id: '3', name: '10-A Sayısal', school: 'Atatürk Anadolu Lisesi', studentCount: 25 },
  { id: '4', name: '12-B MF', school: 'Atatürk Anadolu Lisesi', studentCount: 30 },
]

export type ExamStatus = 'Hazır' | 'Taslak' | 'İşleniyor' | 'Tamamlandı' | 'Başarısız' | 'Atama Bekliyor'

export const mockExams = [
  {
    id: '1',
    name: 'kaan deneme',
    className: 'Sınıf #2',
    date: '22 Nisan 2026',
    dateShort: '22 Nis',
    status: 'Hazır' as ExamStatus,
    pageCount: 4,
    questionCount: 11,
    studentCount: 2,
    totalPoints: 120,
  },
  {
    id: '2',
    name: 'Ale',
    className: 'Sınıf #2',
    date: '22 Nisan 2026',
    dateShort: '22 Nis',
    status: 'Hazır' as ExamStatus,
    pageCount: 3,
    questionCount: 8,
    studentCount: 3,
    totalPoints: 80,
  },
  {
    id: '3',
    name: 'Deneme',
    className: 'Sınıf #2',
    date: '21 Nisan 2026',
    dateShort: '21 Nis',
    status: 'Hazır' as ExamStatus,
    pageCount: 5,
    questionCount: 15,
    studentCount: 4,
    totalPoints: 100,
  },
  {
    id: '4',
    name: 'AYT Geometri Tarama 2',
    className: '12-A SAYISAL',
    date: '21 Nisan 2026',
    dateShort: '21 Nis',
    status: 'Taslak' as ExamStatus,
    pageCount: 4,
    questionCount: 11,
    studentCount: 0,
    totalPoints: 100,
  },
  {
    id: '5',
    name: 'TYT Matematik Deneme 3',
    className: '11-B SÖZEL',
    date: '15 Nisan 2026',
    dateShort: '15 Nis',
    status: 'Tamamlandı' as ExamStatus,
    pageCount: 6,
    questionCount: 20,
    studentCount: 32,
    totalPoints: 100,
  },
]

export const mockStudents = [
  {
    id: '1',
    name: 'Ayse Aydin',
    initials: 'AA',
    matchStatus: 'Manuel eşleşti',
    scorePercent: 99.2,
    rawScore: 119,
    maxScore: 120,
  },
  {
    id: '2',
    name: 'Can Demir',
    initials: 'CD',
    matchStatus: 'Eşleşti',
    scorePercent: 90,
    rawScore: 18,
    maxScore: 20,
  },
]

export const mockQuestions = [
  {
    id: '1',
    number: 1,
    page: 3,
    studentId: '1',
    questionText: 'a) When and where was the Hope for Tomorrow Foundation established?',
    studentAnswer: 'Hope for Tomorrow Foundation in 2005 in London.',
    expectedAnswer: 'It was established in 2005 in London.',
    rubric: 'Correct date and location required.',
    evaluationSummary: 'Correct answer.',
    score: 7,
    maxScore: 7,
    status: 'Puanlandı',
    ocrConfidence: 95,
    scoringConfidence: 95,
  },
  {
    id: '2',
    number: 2,
    page: 3,
    studentId: '1',
    questionText: 'b) What is the main goal of the Hope for Tomorrow Foundation?',
    studentAnswer: 'To provide education and support to underprivileged children.',
    expectedAnswer: 'To provide education and opportunities to children in need.',
    rubric: 'Key concepts of education and children must be mentioned.',
    evaluationSummary: 'Partially correct, key concepts present.',
    score: 5,
    maxScore: 7,
    status: 'Puanlandı',
    ocrConfidence: 88,
    scoringConfidence: 72,
  },
  {
    id: '3',
    number: 3,
    page: 4,
    studentId: '1',
    questionText: 'c) How many countries does the foundation currently operate in?',
    studentAnswer: 'The foundation operates in 15 countries.',
    expectedAnswer: 'The foundation operates in 12 countries.',
    rubric: 'Exact number required.',
    evaluationSummary: 'Incorrect number provided.',
    score: 0,
    maxScore: 6,
    status: 'Puanlandı',
    ocrConfidence: 91,
    scoringConfidence: 85,
  },
]

export const mockOcrJobs = [
  {
    id: '1',
    name: 'Sınav #6-page-1',
    examName: 'Sınav #6-page-1',
    date: '22 Nis 2026',
    time: '17:09',
    status: 'Tamamlandı' as ExamStatus,
    progress: 100,
    statusText: 'İşlem tamamlandı',
    thumbnail: 'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/s%C4%B1nav_kag%C4%B1d%C4%B1_detay.PNG-S6e2LD77u58lr5kksfTCqWKJgoLVw9.png',
  },
  {
    id: '2',
    name: 'Sınav #5-page-2',
    examName: 'Sınav #5-page-2',
    date: '22 Nis 2026',
    time: '17:07',
    status: 'Tamamlandı' as ExamStatus,
    progress: 100,
    statusText: 'İşlem tamamlandı',
    thumbnail: 'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/s%C4%B1nav_kag%C4%B1d%C4%B1_detay.PNG-S6e2LD77u58lr5kksfTCqWKJgoLVw9.png',
  },
  {
    id: '3',
    name: 'Sınav #4-page-3',
    examName: 'Sınav #4-page-3',
    date: '22 Nis 2026',
    time: '16:55',
    status: 'Tamamlandı' as ExamStatus,
    progress: 100,
    statusText: 'İşlem tamamlandı',
    thumbnail: 'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/s%C4%B1nav_kag%C4%B1d%C4%B1_detay.PNG-S6e2LD77u58lr5kksfTCqWKJgoLVw9.png',
  },
]

// ==================== STUDENT MOCK DATA ====================

export type ExamStatusCode = 'READY' | 'PROCESSING' | 'DRAFT' | 'FAILED'

export interface StudentExam {
  examId: number
  classId: number
  title: string
  status: ExamStatusCode
  createdAt: string
  awardedPoints?: number
  maxPoints?: number
  scorePercentage?: number
}

export interface QuestionItem {
  id: number
  pageNumber: number
  questionOrder: number
  sourceQuestionId?: string
  questionText?: string
  studentAnswer?: string
  confidence?: number
  questionType?: string
  expectedAnswer?: string
  gradingRubric?: string
  maxPoints?: number
  awardedPoints?: number
  gradingConfidence?: number
  gradingStatus?: string
  evaluationSummary?: string
  correct?: boolean
}

export interface StudentDashboardSummary {
  totalExams: number
  readyExams: number
  processingExams: number
  draftExams: number
  latestExams: StudentExam[]
}

export const mockStudentSummary: StudentDashboardSummary = {
  totalExams: 8,
  readyExams: 5,
  processingExams: 1,
  draftExams: 2,
  latestExams: [],
}

export const mockStudentExams: StudentExam[] = [
  {
    examId: 1,
    classId: 2,
    title: 'Matematik Deneme Sınavı 1',
    status: 'READY',
    createdAt: '2026-04-22T10:00:00Z',
    awardedPoints: 85,
    maxPoints: 100,
    scorePercentage: 85,
  },
  {
    examId: 2,
    classId: 2,
    title: 'Türkçe Okuduğunu Anlama',
    status: 'READY',
    createdAt: '2026-04-20T10:00:00Z',
    awardedPoints: 72,
    maxPoints: 80,
    scorePercentage: 90,
  },
  {
    examId: 3,
    classId: 2,
    title: 'Fizik Kuvvet ve Hareket',
    status: 'PROCESSING',
    createdAt: '2026-04-18T10:00:00Z',
  },
  {
    examId: 4,
    classId: 2,
    title: 'Kimya Mol Hesapları',
    status: 'READY',
    createdAt: '2026-04-15T10:00:00Z',
    awardedPoints: 60,
    maxPoints: 100,
    scorePercentage: 60,
  },
  {
    examId: 5,
    classId: 2,
    title: 'Biyoloji Hücre Bölünmesi',
    status: 'DRAFT',
    createdAt: '2026-04-10T10:00:00Z',
  },
  {
    examId: 6,
    classId: 2,
    title: 'Tarih Osmanlı Dönemi',
    status: 'READY',
    createdAt: '2026-04-08T10:00:00Z',
    awardedPoints: 44,
    maxPoints: 50,
    scorePercentage: 88,
  },
  {
    examId: 7,
    classId: 2,
    title: 'İngilizce Grammar Test',
    status: 'FAILED',
    createdAt: '2026-04-05T10:00:00Z',
  },
  {
    examId: 8,
    classId: 2,
    title: 'Coğrafya Türkiye İklimi',
    status: 'READY',
    createdAt: '2026-04-01T10:00:00Z',
    awardedPoints: 78,
    maxPoints: 100,
    scorePercentage: 78,
  },
]

export const mockExamQuestions: QuestionItem[] = [
  {
    id: 1,
    pageNumber: 1,
    questionOrder: 1,
    questionText: 'a) Hope for Tomorrow Vakfı ne zaman ve nerede kuruldu?',
    studentAnswer: 'Hope for Tomorrow Vakfı 2005 yılında Londra\'da kuruldu.',
    expectedAnswer: '2005 yılında Londra\'da kuruldu.',
    evaluationSummary: 'Doğru tarih ve konum belirtilmiş.',
    maxPoints: 10,
    awardedPoints: 10,
    confidence: 0.97,
    gradingConfidence: 0.95,
    questionType: 'OPEN_ENDED',
    correct: true,
    gradingStatus: 'GRADED',
  },
  {
    id: 2,
    pageNumber: 1,
    questionOrder: 2,
    questionText: 'b) Vakfın temel amacı nedir?',
    studentAnswer: 'Dezavantajlı çocuklara eğitim ve destek sağlamak.',
    expectedAnswer: 'İhtiyaç sahibi çocuklara eğitim ve fırsatlar sunmak.',
    evaluationSummary: 'Kısmen doğru, temel kavramlar mevcut.',
    maxPoints: 10,
    awardedPoints: 7,
    confidence: 0.88,
    gradingConfidence: 0.72,
    questionType: 'OPEN_ENDED',
    correct: false,
    gradingStatus: 'GRADED',
  },
  {
    id: 3,
    pageNumber: 2,
    questionOrder: 3,
    questionText: 'c) Vakfın şu anda kaç ülkede faaliyeti bulunmaktadır?',
    studentAnswer: 'Vakıf 15 ülkede faaliyet göstermektedir.',
    expectedAnswer: 'Vakıf 12 ülkede faaliyet göstermektedir.',
    evaluationSummary: 'Yanlış sayı verilmiş.',
    maxPoints: 10,
    awardedPoints: 0,
    confidence: 0.91,
    gradingConfidence: 0.85,
    questionType: 'OPEN_ENDED',
    correct: false,
    gradingStatus: 'GRADED',
  },
  {
    id: 4,
    pageNumber: 2,
    questionOrder: 4,
    questionText: 'd) Programın başarı kriteri nedir?',
    studentAnswer: 'Öğrencilerin okul başarısının artması ve mezuniyet oranları.',
    expectedAnswer: 'Akademik başarı ve mezuniyet oranlarının iyileşmesi.',
    evaluationSummary: 'Doğru kavramlar ifade edilmiş.',
    maxPoints: 10,
    awardedPoints: 9,
    confidence: 0.93,
    gradingConfidence: 0.90,
    questionType: 'OPEN_ENDED',
    correct: true,
    gradingStatus: 'GRADED',
  },
  {
    id: 5,
    pageNumber: 3,
    questionOrder: 5,
    questionText: 'e) Programın finansman kaynağı nedir?',
    studentAnswer: 'Bağışlar ve hükümet destekleri.',
    expectedAnswer: 'Özel bağışlar, kurumsal sponsorluklar ve hibe fonları.',
    evaluationSummary: 'Kısmen doğru ancak eksik bilgi.',
    maxPoints: 10,
    awardedPoints: 5,
    confidence: 0.79,
    gradingConfidence: 0.68,
    questionType: 'OPEN_ENDED',
    correct: false,
    gradingStatus: 'GRADED',
  },
]

// ==================== PARENT MOCK DATA ====================

export interface ParentStudentSummary {
  studentId: number
  fullName: string
  email: string
  classId?: number
  totalExams: number
  readyExams: number
  latestExamId?: number
  latestExamTitle?: string
  latestExamStatus?: ExamStatusCode
  latestExamCreatedAt?: string
}

export interface ParentStudentExam {
  examId: number
  classId: number
  title: string
  status: ExamStatusCode
  createdAt: string
  awardedPoints?: number
  maxPoints?: number
  scorePercentage?: number
}

export const mockParentStudents: ParentStudentSummary[] = [
  {
    studentId: 101,
    fullName: 'Ahmet Yılmaz',
    email: 'ahmet@school.edu.tr',
    classId: 2,
    totalExams: 8,
    readyExams: 5,
    latestExamId: 1,
    latestExamTitle: 'Matematik Deneme Sınavı 1',
    latestExamStatus: 'READY',
    latestExamCreatedAt: '2026-04-22T10:00:00Z',
  },
  {
    studentId: 102,
    fullName: 'Zeynep Kaya',
    email: 'zeynep@school.edu.tr',
    classId: 3,
    totalExams: 5,
    readyExams: 3,
    latestExamId: 2,
    latestExamTitle: 'Türkçe Okuduğunu Anlama',
    latestExamStatus: 'PROCESSING',
    latestExamCreatedAt: '2026-04-20T10:00:00Z',
  },
]

export const mockParentStudentExams: Record<number, ParentStudentExam[]> = {
  101: [
    {
      examId: 1,
      classId: 2,
      title: 'Matematik Deneme Sınavı 1',
      status: 'READY',
      createdAt: '2026-04-22T10:00:00Z',
      awardedPoints: 85,
      maxPoints: 100,
      scorePercentage: 85,
    },
    {
      examId: 3,
      classId: 2,
      title: 'Fizik Kuvvet ve Hareket',
      status: 'PROCESSING',
      createdAt: '2026-04-18T10:00:00Z',
    },
    {
      examId: 4,
      classId: 2,
      title: 'Kimya Mol Hesapları',
      status: 'READY',
      createdAt: '2026-04-15T10:00:00Z',
      awardedPoints: 60,
      maxPoints: 100,
      scorePercentage: 60,
    },
    {
      examId: 6,
      classId: 2,
      title: 'Tarih Osmanlı Dönemi',
      status: 'READY',
      createdAt: '2026-04-08T10:00:00Z',
      awardedPoints: 44,
      maxPoints: 50,
      scorePercentage: 88,
    },
  ],
  102: [
    {
      examId: 2,
      classId: 3,
      title: 'Türkçe Okuduğunu Anlama',
      status: 'PROCESSING',
      createdAt: '2026-04-20T10:00:00Z',
    },
    {
      examId: 5,
      classId: 3,
      title: 'Biyoloji Hücre Bölünmesi',
      status: 'DRAFT',
      createdAt: '2026-04-10T10:00:00Z',
    },
  ],
}
