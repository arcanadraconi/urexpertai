import { FileText } from 'lucide-react'

export function Logo() {
  return (
    <div className="flex items-center gap-2">
      <FileText className="w-8 h-8 text-[#1d7f84]" />
      <span className="text-2xl font-semibold text-[#1d7f84]">URExpert</span>
    </div>
  )
}