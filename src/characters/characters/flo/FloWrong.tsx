// Flo/wrong — Figma node 18:253
// Asset URLs expire 7 days from export. Refresh via: get_design_context(nRp0M7stnwuRvbzApLsK8w, 18:253)

const imgBody = 'https://www.figma.com/api/mcp/asset/79b9d0ea-2d05-47fd-b08e-de6252ca95fa'
const imgHead = 'https://www.figma.com/api/mcp/asset/8ac9b084-1999-41c7-9908-08989f89062b'
const imgEyeNormal = 'https://www.figma.com/api/mcp/asset/1ec34a62-d4b6-45a3-9d68-1e61f71bc4bb'
const imgCheek = 'https://www.figma.com/api/mcp/asset/368a2916-a0a2-41ff-916a-c2f4ddd3fbf4'
const imgMouthWrong = 'https://www.figma.com/api/mcp/asset/f51016e4-6f65-4d13-82e7-64999d1d2762'
const imgHandScratch = 'https://www.figma.com/api/mcp/asset/bcbbcb9e-3f3f-4a3f-bbe8-14f41727ae32'

const NATIVE_SIZE = 200

interface FloWrongProps {
  size?: number
  className?: string
}

export default function FloWrong({ size = NATIVE_SIZE, className }: FloWrongProps) {
  const scale = size / NATIVE_SIZE

  return (
    <div
      style={{ width: size, height: size, overflow: 'hidden', flexShrink: 0 }}
      className={className}
      data-character="flo"
      data-state="wrong"
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
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgHead} />
        </div>
        <div className="absolute inset-[25.5%_23%_69.5%_58%]" data-part="eye">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgEyeNormal} />
        </div>
        <div className="absolute inset-[30.5%_15.5%_66.5%_51%]" data-part="cheek">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgCheek} />
        </div>
        <div className="absolute inset-[32.5%_26.5%_61%_61.5%]" data-part="mouth">
          <img alt="" className="absolute block inset-0 max-w-none size-full" src={imgMouthWrong} />
        </div>
        <div
          className="absolute flex items-center justify-center"
          style={{ height: 61.239, left: 142.29, top: 2.63, width: 54.882 }}
          data-part="gesture"
        >
          <div style={{ transform: 'scaleY(-1) rotate(172.29deg)', flexShrink: 0 }}>
            <div style={{ height: 55.313, position: 'relative', width: 47.893 }}>
              <div className="absolute inset-[-3.62%_-4.18%_-3.62%_-4.17%]">
                <img alt="" className="block max-w-none size-full" src={imgHandScratch} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
