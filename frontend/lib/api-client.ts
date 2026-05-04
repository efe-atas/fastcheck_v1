// API Client for interacting with the Spring Boot backend
// Requests go through Next.js rewrites proxy → /api/* → http://localhost:8080/*
// This eliminates CORS issues since the browser only talks to the same origin.
const API_BASE = '/api'

// --- Types ---
export interface AuthResponse {
  userId: number
  email: string
  accessToken: string
  refreshToken: string
  /** Decoded from the JWT access token – not returned directly by the backend */
  role?: string
}

export interface PagedResponse<T> {
  items: T[]
  page: number
  size: number
  totalElements: number
  totalPages: number
}

// Student Models
export interface StudentExamListItem {
  examId: number
  classId: number
  title: string
  status: string
  createdAt: string
  awardedPoints?: number
  maxPoints?: number
  scorePercentage?: number
}

export interface StudentDashboardSummary {
  totalExams: number
  readyExams: number
  processingExams: number
  draftExams: number
  latestExams: StudentExamListItem[]
}

// Question Model
export interface QuestionResponse {
  id: number
  pageNumber: number
  questionOrder: number
  sourceQuestionId?: string
  questionText?: string
  studentAnswer?: string
  confidence: number
  questionType?: string
  expectedAnswer?: string
  gradingRubric?: string
  maxPoints?: number
  awardedPoints?: number
  gradingConfidence?: number
  gradingStatus?: string
  evaluationSummary?: string
  correct?: boolean
  studentId?: number
  studentName?: string
  matchingStatus?: string
}

// Parent Models
export interface ParentStudentSummary {
  studentId: number
  fullName: string
  email: string
  classId?: number
  totalExams: number
  readyExams: number
  latestExamId?: number
  latestExamTitle?: string
  latestExamStatus?: string
  latestExamCreatedAt?: string
}

export interface ParentDashboardSummary {
  linkedStudents: number
  students: ParentStudentSummary[]
}

// Teacher Models
export interface ExamResponse {
  examId: number
  classId: number
  title: string
  status: string
  createdAt: string
}

export interface CreateQuestionRequest {
  questionOrder: number
  pageNumber: number
  questionType: string
  expectedAnswer?: string
  gradingRubric?: string
  maxPoints: number
}

export interface CreateExamRequest {
  title: string
  status: string
  questions: CreateQuestionRequest[]
}

export interface OcrJobStatusResponse {
  jobId: string
  requestId: string
  status: string
  retryCount: number
  errorMessage?: string
  createdAt: string
}

export interface TeacherDashboardSummary {
  totalClasses: number
  totalExams: number
  processingExams: number
  readyExams: number
  latestExams: ExamResponse[]
  recentOcrJobs: OcrJobStatusResponse[]
}

export interface ClassWithExamCountResponse {
  classId: number
  schoolId: number
  className: string
  examCount: number
  createdAt: string
}

export interface TeacherStudentRosterResponse {
  userId: number
  fullName: string
  email: string
  classId: number
}

export interface ExamImageResponse {
  imageId: number
  pageOrder: number
  imageUrl: string
  status: string
  errorMessage?: string
  processingStartedAt?: string
  processingCompletedAt?: string
  studentMatch?: any // Update if needed
}

export interface TeacherExamStatusResponse {
  examId: number
  classId: number
  title: string
  examStatus: string
  gradingSystemSummary?: string
  totalMaxPoints?: number
  images: ExamImageResponse[]
  students: TeacherStudentRosterResponse[]
  ocrJobs: OcrJobStatusResponse[]
  questionCount: number
  questions: QuestionResponse[]
  studentClusters: any[]
  studentResults: any[]
}

// --- Fetch Utility ---
function getToken() {
  if (typeof window !== 'undefined') {
    return localStorage.getItem('access_token')
  }
  return null
}

/**
 * Decode a JWT without verifying the signature (client-side only).
 * Returns the payload as a plain object, or null on failure.
 */
export function decodeJwt(token: string): Record<string, any> | null {
  try {
    const base64Url = token.split('.')[1]
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    )
    return JSON.parse(jsonPayload)
  } catch {
    return null
  }
}

async function fetchApi<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const url = `${API_BASE}${endpoint}`
  const headers: Record<string, string> = {}
  
  if (!(options.body instanceof FormData)) {
    headers['Content-Type'] = 'application/json'
  }
  
  Object.assign(headers, options.headers || {})

  const token = getToken()
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const response = await fetch(url, { ...options, headers })
  if (!response.ok) {
    if (response.status === 401) {
      if (typeof window !== 'undefined') {
        localStorage.removeItem('access_token')
        window.location.href = '/login'
      }
    }
    const errorText = await response.text().catch(() => 'Unknown error')
    throw new Error(`API Error ${response.status}: ${errorText}`)
  }
  return response.json()
}

// --- API Methods ---
export const api = {
  // Auth
  login: (data: any) => fetchApi<AuthResponse>('/auth/login', { method: 'POST', body: JSON.stringify(data) }),
  
  // Teacher
  getTeacherDashboard: () => fetchApi<TeacherDashboardSummary>('/v1/teacher/dashboard'),
  listTeacherClasses: () => fetchApi<ClassWithExamCountResponse[]>('/v1/teacher/classes'),
  createClass: (data: { className: string }) => 
    fetchApi<any>('/v1/teacher/classes', { method: 'POST', body: JSON.stringify(data) }),
  listClassExams: (classId: number) => fetchApi<ExamResponse[]>(`/v1/teacher/classes/${classId}/exams`),
  listClassStudents: (classId: number) => fetchApi<PagedResponse<TeacherStudentRosterResponse>>(`/v1/teacher/classes/${classId}/students`),
  addStudentToClass: (classId: number, data: { fullName: string, email: string }) =>
    fetchApi<any>(`/v1/teacher/classes/${classId}/students`, { method: 'POST', body: JSON.stringify(data) }),
  getTeacherExamStatus: (examId: number) => fetchApi<TeacherExamStatusResponse>(`/v1/teacher/exams/${examId}`),
  updateQuestionOverride: (examId: number, questionId: number, data: any) => 
    fetchApi<TeacherExamStatusResponse>(`/v1/teacher/exams/${examId}/questions/${questionId}/override`, {
      method: 'PATCH',
      body: JSON.stringify(data)
    }),
  createExam: (classId: number, data: CreateExamRequest) => 
    fetchApi<ExamResponse>(`/v1/teacher/classes/${classId}/exams`, {
      method: 'POST',
      body: JSON.stringify(data)
    }),
  uploadExamImages: (examId: number, formData: FormData) => 
    fetchApi<any>(`/v1/teacher/exams/${examId}/images`, {
      method: 'POST',
      body: formData
    }),

  // Student
  getStudentDashboard: () => fetchApi<StudentDashboardSummary>('/v1/student/dashboard'),
  listStudentExams: (page = 0, size = 20) => fetchApi<PagedResponse<StudentExamListItem>>(`/v1/student/exams?page=${page}&size=${size}`),
  getStudentExamQuestions: (examId: number) => fetchApi<QuestionResponse[]>(`/v1/student/exams/${examId}/questions`),

  // Parent
  getParentDashboard: () => fetchApi<ParentDashboardSummary>('/v1/parent/dashboard'),
  listParentStudentExams: (studentId: number, page = 0, size = 20) => 
    fetchApi<PagedResponse<StudentExamListItem>>(`/v1/parent/students/${studentId}/exams?page=${page}&size=${size}`),
  getParentExamQuestions: (studentId: number, examId: number) => 
    fetchApi<QuestionResponse[]>(`/v1/parent/students/${studentId}/exams/${examId}/questions`),
}
