/// <reference types="vite/client" />

declare module '*.svg?react' {
  import type { SVGProps, FunctionComponent } from 'react'
  const ReactComponent: FunctionComponent<SVGProps<SVGSVGElement>>
  export default ReactComponent
}
