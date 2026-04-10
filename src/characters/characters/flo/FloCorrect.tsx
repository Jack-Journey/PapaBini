// Flo/correct — Figma node 18:252
// Asset URLs expire 7 days from export. Refresh via: get_design_context(nRp0M7stnwuRvbzApLsK8w, 18:252)

const imgBody = 'https://www.figma.com/api/mcp/asset/4eb86825-ecf4-456f-875f-38ec9baafd5d'
const imgHead = 'https://www.figma.com/api/mcp/asset/1c0427da-86c9-4ab7-b1ec-841297307b1a'
const imgEyeCorrect = 'https://www.figma.com/api/mcp/asset/45c5b06c-b9cf-4bc9-9ae5-08bc96dbe06a'
const imgCheek = 'https://www.figma.com/api/mcp/asset/48ed3464-9bcc-4783-9b05-d8f9aa982c1f'
const imgMouthLaugh = 'https://www.figma.com/api/mcp/asset/57cceafb-e788-4c71-8501-e7f59910d622'
const imgThumbsUp = 'https://www.figma.com/api/mcp/asset/68935e85-e034-4bcc-b4f2-77dfcf425738'

// Native size from Figma — all pixel values are relative to this
const NATIVE_SIZE = 200

interface FloCorrectProps {
  size?: number
  className?: string
}

export default function FloCorrect({ size = NATIVE_SIZE, className }: FloCorrectProps) {
  const scale = size / NATIVE_SIZE

  return (
    <div
      style={{ width: size, height: size, overflow: 'hidden', flexShrink: 0 }}
      className={className}
      data-character="flo"
      data-state="correct"
    >
      <div
        style={{
          width: NATIVE_SIZE,
          height: NATIVE_SIZE,
          position: 'relative',
          transform: `scale(${scale})`,
          transformOrigin: 'top left',
        }}
      >
        <div className="absolute inset-[34.5%_14.5%_9.5%_18.75%]" data-part="body">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgBody} />
        </div>
        <div className="absolute inset-[34.5%_14.5%_9.5%_18.75%]" data-part="body-lower">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgBody} />
        </div>
        <div className="absolute inset-[7.5%_7.5%_42.5%_42.5%]" data-part="head">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgHead} />
        </div>
        <div className="absolute inset-[24.5%_22.5%_72%_57.5%]" data-part="eye">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgEyeCorrect} />
        </div>
        <div className="absolute inset-[30.5%_15.5%_66.5%_51%]" data-part="cheek">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgCheek} />
        </div>
        <div className="absolute inset-[32%_28%_57.5%_63%]" data-part="mouth">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMouthLaugh} />
        </div>
        <div
          className="absolute"
          style={{ height: 102, left: 48, top: 50, width: 71 }}
          data-part="gesture"
        >
          <div className="absolute inset-[-2.45%_-3.52%]">
            <img alt="" className="block max-w-none size-full" src={imgThumbsUp} />
          </div>
        </div>
      </div>
    </div>
  )
}
