// Flo/smile — Figma node 18:254
// Asset URLs expire 7 days from export. Refresh via: get_design_context(nRp0M7stnwuRvbzApLsK8w, 18:254)

const imgBody = 'https://www.figma.com/api/mcp/asset/d012973f-543c-4e90-b045-67485a94d33d'
const imgBody1 = 'https://www.figma.com/api/mcp/asset/461a6c79-dfe5-4f5a-addc-a00ed18b260e'
const imgEyeNormal = 'https://www.figma.com/api/mcp/asset/f94ce4a0-abb6-43a1-9287-8a9e7b91d6a7'
const imgCheek = 'https://www.figma.com/api/mcp/asset/99687edc-eac8-42e8-931a-503cf9d12d37'
const imgMouthSmile = 'https://www.figma.com/api/mcp/asset/385f09c4-70fe-4492-a940-e2715499d38e'

const NATIVE_SIZE = 200

interface FloSmileProps {
  size?: number
  className?: string
}

export default function FloSmile({ size = NATIVE_SIZE, className }: FloSmileProps) {
  const scale = size / NATIVE_SIZE

  return (
    <div
      style={{ width: size, height: size, overflow: 'hidden', flexShrink: 0 }}
      className={className}
      data-character="flo"
      data-state="smile"
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
        <div className="absolute inset-[7.5%_7.5%_42.5%_42.5%]" data-part="head">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgBody1} />
        </div>
        <div className="absolute inset-[25.5%_23%_69.5%_58%]" data-part="eye">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgEyeNormal} />
        </div>
        <div className="absolute inset-[30.5%_15.5%_66.5%_51%]" data-part="cheek">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgCheek} />
        </div>
        <div className="absolute inset-[32.5%_26.5%_61%_61.5%]" data-part="mouth">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMouthSmile} />
        </div>
      </div>
    </div>
  )
}
