import AppKit
import ImageIO
import UniformTypeIdentifiers

// Original Photo Hub artwork. Opaque RGB square, with antialiased vector shapes.
let output = CommandLine.arguments[1]
let size = 1024
let ctx = CGContext(data:nil, width:size, height:size, bitsPerComponent:8, bytesPerRow:0,
    space:CGColorSpace(name:CGColorSpace.sRGB)!, bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext:ctx, flipped:false)
ctx.setShouldAntialias(true)
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
    NSColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: 1)
}
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat, _ fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: NSRect(x:x,y:y,width:w,height:h), xRadius:radius,yRadius:radius).fill()
}
rect(0,0,1024,1024,0,color(50,103,80))
// A quiet stacked album and a warm, high contrast landscape.
rect(194,270,594,520,64,color(142,176,147))
rect(242,222,594,520,64,color(250,249,246))
rect(284,264,510,436,30,color(220,233,215))
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: CGRect(x:284,y:264,width:510,height:436), cornerWidth:30,cornerHeight:30,transform:nil))
ctx.clip()
color(109,151,116).setFill()
let mountain = NSBezierPath()
mountain.move(to:NSPoint(x:270,y:264)); mountain.line(to:NSPoint(x:270,y:350))
mountain.line(to:NSPoint(x:449,y:567)); mountain.line(to:NSPoint(x:625,y:351))
mountain.line(to:NSPoint(x:810,y:351)); mountain.line(to:NSPoint(x:810,y:264)); mountain.close(); mountain.fill()
color(50,103,80).setFill()
let foreground = NSBezierPath()
foreground.move(to:NSPoint(x:335,y:264)); foreground.line(to:NSPoint(x:638,y:505))
foreground.line(to:NSPoint(x:810,y:350)); foreground.line(to:NSPoint(x:810,y:264)); foreground.close(); foreground.fill()
color(219,174,84).setFill()
NSBezierPath(ovalIn:NSRect(x:620,y:554,width:108,height:108)).fill()
ctx.restoreGState()
NSGraphicsContext.restoreGraphicsState()
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath:output) as CFURL,
    UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, ctx.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
