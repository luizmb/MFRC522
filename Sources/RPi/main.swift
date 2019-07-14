import Foundation
import Glibc
import SwiftyGPIO

typealias Byte = UInt8

class MFRC522 {
    let NRSTPD: GPIOName            = .P22

    let MAX_LEN: Int                = 16

    let PCD_IDLE: Byte              = 0x00
    let PCD_AUTHENT: Byte           = 0x0E
    let PCD_RECEIVE: Byte           = 0x08
    let PCD_TRANSMIT: Byte          = 0x04
    let PCD_TRANSCEIVE: Byte        = 0x0C
    let PCD_RESETPHASE: Byte        = 0x0F
    let PCD_CALCCRC: Byte           = 0x03

    let PICC_REQIDL: Byte           = 0x26
    let PICC_REQALL: Byte           = 0x52
    let PICC_ANTICOLL: Byte         = 0x93
    let PICC_SElECTTAG: Byte        = 0x93
    let PICC_AUTHENT1A: Byte        = 0x60
    let PICC_AUTHENT1B: Byte        = 0x61
    let PICC_READ: Byte             = 0x30
    let PICC_WRITE: Byte            = 0xA0
    let PICC_DECREMENT: Byte        = 0xC0
    let PICC_INCREMENT: Byte        = 0xC1
    let PICC_RESTORE: Byte          = 0xC2
    let PICC_TRANSFER: Byte         = 0xB0
    let PICC_HALT: Byte             = 0x50

    let MI_OK: Byte                 = 0
    let MI_NOTAGERR: Byte           = 1
    let MI_ERR: Byte                = 2

    let Reserved00: Byte            = 0x00
    let CommandReg: Byte            = 0x01
    let CommIEnReg: Byte            = 0x02
    let DivlEnReg: Byte             = 0x03
    let CommIrqReg: Byte            = 0x04
    let DivIrqReg: Byte             = 0x05
    let ErrorReg: Byte              = 0x06
    let Status1Reg: Byte            = 0x07
    let Status2Reg: Byte            = 0x08
    let FIFODataReg: Byte           = 0x09
    let FIFOLevelReg: Byte          = 0x0A
    let WaterLevelReg: Byte         = 0x0B
    let ControlReg: Byte            = 0x0C
    let BitFramingReg: Byte         = 0x0D
    let CollReg: Byte               = 0x0E
    let Reserved01: Byte            = 0x0F

    let Reserved10: Byte            = 0x10
    let ModeReg: Byte               = 0x11
    let TxModeReg: Byte             = 0x12
    let RxModeReg: Byte             = 0x13
    let TxControlReg: Byte          = 0x14
    let TxAutoReg: Byte             = 0x15
    let TxSelReg: Byte              = 0x16
    let RxSelReg: Byte              = 0x17
    let RxThresholdReg: Byte        = 0x18
    let DemodReg: Byte              = 0x19
    let Reserved11: Byte            = 0x1A
    let Reserved12: Byte            = 0x1B
    let MifareReg: Byte             = 0x1C
    let Reserved13: Byte            = 0x1D
    let Reserved14: Byte            = 0x1E
    let SerialSpeedReg: Byte        = 0x1F

    let Reserved20: Byte            = 0x20
    let CRCResultRegM: Byte         = 0x21
    let CRCResultRegL: Byte         = 0x22
    let Reserved21: Byte            = 0x23
    let ModWidthReg: Byte           = 0x24
    let Reserved22: Byte            = 0x25
    let RFCfgReg: Byte              = 0x26
    let GsNReg: Byte                = 0x27
    let CWGsPReg: Byte              = 0x28
    let ModGsPReg: Byte             = 0x29
    let TModeReg: Byte              = 0x2A
    let TPrescalerReg: Byte         = 0x2B
    let TReloadRegH: Byte           = 0x2C
    let TReloadRegL: Byte           = 0x2D
    let TCounterValueRegH: Byte     = 0x2E
    let TCounterValueRegL: Byte     = 0x2F

    let Reserved30: Byte            = 0x30
    let TestSel1Reg: Byte           = 0x31
    let TestSel2Reg: Byte           = 0x32
    let TestPinEnReg: Byte          = 0x33
    let TestPinValueReg: Byte       = 0x34
    let TestBusReg: Byte            = 0x35
    let AutoTestReg: Byte           = 0x36
    let VersionReg: Byte            = 0x37
    let AnalogTestReg: Byte         = 0x38
    let TestDAC1Reg: Byte           = 0x39
    let TestDAC2Reg: Byte           = 0x3A
    let TestADCReg: Byte            = 0x3B
    let Reserved31: Byte            = 0x3C
    let Reserved32: Byte            = 0x3D
    let Reserved33: Byte            = 0x3E
    let Reserved34: Byte            = 0x3F

    var serNum: [Byte]              = []
    let board: SupportedBoard       = .RaspberryPi3
    let speed: UInt32               = 1000000
    let spi: SysFSSPI
    let gpios: [GPIOName: GPIO]

    init() {
        spi = (SwiftyGPIO.hardwareSPIs(for: board)?.first as? SysFSSPI)!
        gpios = SwiftyGPIO.GPIOs(for: board)
        spi.setMaxSpeedHz(speed)

        //        GPIO.setmode(GPIO.BOARD)
        let nrstpd = gpios[NRSTPD]!
        nrstpd.direction = .OUT
        nrstpd.value = 1
        start()
    }

    func start() {
        reset()

        write(addr: TModeReg, val: 0x8D)
        write(addr: TPrescalerReg, val: 0x3E)
        write(addr: TReloadRegL, val: 30)
        write(addr: TReloadRegH, val: 0)
        write(addr: TxAutoReg, val: 0x40)
        write(addr: ModeReg, val: 0x3D)
        antennaOn()
    }

    func reset() {
        write(addr: CommandReg, val: PCD_RESETPHASE)
    }

    func write(addr: Byte, val: Byte) {
        spi.sendData([
            (addr << 1) & 0x7E,
            val
        ])
    }

    func write(blockAddr: Byte, writeData: [Byte]) {
        var buff: [Byte] = [
            PICC_WRITE,
            blockAddr
        ]
        let crc = calulateCRC(pIndata: buff)
        buff.append(crc[0])
        buff.append(crc[1])

        var (status, backData, backLen) = toCard(command: PCD_TRANSCEIVE, sendData: buff)
        if status != MI_OK || backLen != 4 || (backData[0] & 0x0F) != 0x0A {
            status = MI_ERR
        }

        print("\(backLen) backdata & 0x0F == 0x0A \(backData[0] & 0x0F)")
        if status == MI_OK {
            var buf: [Byte] = []
            for i in 0 ..< 16 {
                buf.append(writeData[i])
            }
            let crc = calulateCRC(pIndata: buf)
            buf.append(crc[0])
            buf.append(crc[1])
            let (status, backData, backLen) = toCard(command: PCD_TRANSCEIVE, sendData: buf)
            if status != MI_OK || backLen != 4 || (backData[0] & 0x0F) != 0x0A {
                print("Error while writing")
            }
            if status == MI_OK {
                print("Data written")
            }
        }
    }

    func read(addr: Byte) -> Byte {
        let val = spi.sendDataAndRead([
            ((addr << 1) & 0x7E) | 0x80,
            0
        ])
        return val[1]
    }

    func read(blockAddr: Byte) {
        var recvData: [Byte] = [
            PICC_READ,
            blockAddr
        ]
        let pOut = calulateCRC(pIndata: recvData)
        recvData.append(pOut[0])
        recvData.append(pOut[1])
        let (status, backData, backLen) = toCard(command: PCD_TRANSCEIVE, sendData: recvData)
        if status != MI_OK {
            print("Error while reading!")
        }
        if backData.count == 16 {
            print("Sector \(blockAddr) -> \(backData.map { String(format: "%02hhx", $0) }.joined(separator: ", "))")
        }
    }

    func setBitMask(reg: Byte, mask: Byte) {
        let tmp = read(addr: reg)
        write(addr: reg, val: tmp | mask)
    }

    func clearBitMask(reg: Byte, mask: Byte) {
        let tmp = read(addr: reg)
        write(addr: reg, val: tmp & (~mask))
    }

    func antennaOn() {
        let temp = read(addr: TxControlReg)
        if ~(temp & 0x03) != 0 {
            setBitMask(reg: TxControlReg, mask: 0x03)
        }
    }

    func antennaOff() {
        clearBitMask(reg: TxControlReg, mask: 0x03)
    }

    func toCard(command: Byte, sendData: [Byte]) -> (status: Byte, backData: [Byte], backLen: Int) {
        var backData: [Byte] = []
        var backLen = 0
        var status = MI_ERR
        var irqEn: Byte = 0x00
        var waitIRq: Byte = 0x00

        if command == PCD_AUTHENT {
            irqEn = 0x12
            waitIRq = 0x10
        }

        if command == PCD_TRANSCEIVE {
            irqEn = 0x77
            waitIRq = 0x30
        }

        write(addr: CommIEnReg, val: irqEn | 0x80)
        clearBitMask(reg: CommIrqReg, mask: 0x80)
        setBitMask(reg: FIFOLevelReg, mask: 0x80)

        write(addr: CommandReg, val: PCD_IDLE)

        sendData.forEach { byteToSend in
            write(addr: FIFODataReg, val: byteToSend)
        }

        write(addr: CommandReg, val: command)

        if command == self.PCD_TRANSCEIVE {
            setBitMask(reg: BitFramingReg, mask: 0x80)
        }

        var i = 2000
        var n: Byte = 0
        repeat {
            n = read(addr: CommIrqReg)
            i = i - 1
        } while !(i == 0 || (n & 0x01) != 0 || (n & waitIRq) != 0)

        clearBitMask(reg: BitFramingReg, mask: 0x80)

        if i != 0 {
            if (read(addr: ErrorReg) & 0x1B) == 0x00 {
                status = MI_OK

                if (n & irqEn & 0x01) != 0 {
                    status = MI_NOTAGERR
                }

                if command == PCD_TRANSCEIVE {
                    var size = Int(read(addr: FIFOLevelReg))
                    let lastBits = Int(read(addr: ControlReg) & 0x07)

                    if lastBits != 0 {
                        backLen = (size - 1) * 8 + lastBits
                    } else {
                        backLen = size * 8
                    }

                    if size == 0 { size = 1 }
                    if size > MAX_LEN { size = MAX_LEN }
                    for _ in 0 ..< size {
                        backData.append(read(addr: FIFODataReg))
                    }
                }
            } else {
                status = MI_ERR
            }
        }

        return (status: status, backData: backData, backLen: backLen)
    }

    func request(reqMode: Byte) -> (status: Byte, backBits: Int) {
        write(addr: BitFramingReg, val: 0x07)

        let (status, _, backBits) = toCard(command: PCD_TRANSCEIVE, sendData: [reqMode])

        if status != MI_OK || backBits != 0x10 {
            return (status: MI_ERR, backBits: backBits)
        }

        return (status, backBits)
    }

    func anticoll() -> (status: Byte, backData: [Byte]) {
        write(addr: BitFramingReg, val: 0x00)

        let serNum = [PICC_ANTICOLL, 0x20]
        var (status, backData, backBits) = toCard(command: PCD_TRANSCEIVE, sendData: serNum)

        if status == MI_OK {
            if backData.count == 5 {
                if backData.dropLast().reduce(0, ^) != backData.last {
                    status = MI_ERR
                }
            } else {
                status = MI_ERR
            }
        }

        return (status: status, backData: backData)
    }

    func calulateCRC(pIndata: [Byte]) -> [Byte] {
        clearBitMask(reg: DivIrqReg, mask: 0x04)
        setBitMask(reg: FIFOLevelReg, mask: 0x80)
        pIndata.forEach {
            write(addr: FIFODataReg, val: $0)
        }
        write(addr: CommandReg, val: PCD_CALCCRC)
        var i = 0xFF
        var n: Byte
        repeat {
            n = read(addr: DivIrqReg)
            i = i - 1
        } while ((i != 0) && (n & 0x04) == 0)

        return [
            read(addr: CRCResultRegL),
            read(addr: CRCResultRegM)
        ]
    }

    func selectTag(serNum: [Byte]) -> Byte {
        var buf: [Byte] = [PICC_SElECTTAG, 0x70]
        for i in 0 ..< 5 {
            buf.append(serNum[i])
        }
        let pOut = calulateCRC(pIndata: buf)
        buf.append(pOut[0])
        buf.append(pOut[1])
        let (status, backData, backLen) = toCard(command: PCD_TRANSCEIVE, sendData: buf)

        if status == MI_OK && backLen == 0x18 {
            print("Size: \(backData[0])")
            return backData[0]
        }
        else {
            return 0
        }
    }

    func auth(authMode: Byte, blockAddr: Byte, sectorkey: [Byte], serNum: [Byte]) -> Byte {
        var buff: [Byte] = []

        // First byte should be the authMode (A or B)
        buff.append(authMode)

        // Second byte is the trailerBlock (usually 7)
        buff.append(blockAddr)

        // Now we need to append the authKey which usually is 6 bytes of 0xFF
        buff.append(contentsOf: sectorkey)

        // Next we append the first 4 bytes of the UID
        for i in 0 ..< 4 {
            buff.append(serNum[i])
        }

        // Now we start the authentication itself
        let (status, backData, backLen) = toCard(command: PCD_AUTHENT, sendData: buff)

        // Check if an error occurred
        if status != MI_OK {
            print("AUTH ERROR!!")
        }

        if (read(addr: Status2Reg) & 0x08) == 0 {
            print("AUTH ERROR(status2reg & 0x08) != 0")
        }

        return status
    }

    func stopCrypto() {
        clearBitMask(reg: Status2Reg, mask: 0x08)
    }

    func dumpClassic1K(key: [Byte], uid: [Byte]) {
        for i: Byte in 0 ..< 64 {
            let status = auth(authMode: PICC_AUTHENT1A, blockAddr: i, sectorkey: key, serNum: uid)
            // Check if authenticated
            if status == MI_OK {
                read(blockAddr: i)
            } else {
                print("Authentication error")
            }
        }
    }
}




import Foundation

let group = DispatchGroup()
group.enter()
group.notify(queue: DispatchQueue.main) {
    exit(EXIT_SUCCESS)
}

signal(SIGINT) { signal in
    print("Bye! \(signal)")
    group.leave()
}

// Create an object of the class MFRC522
let rc522 = MFRC522()

// Welcome message
print("Welcome to the MFRC522 data read example")
print("Press Ctrl-C to stop.")

while true {
    // Scan for cards
    let (statusSearch, tagType) = rc522.request(reqMode: rc522.PICC_REQIDL)

    // If a card is found
    if statusSearch == rc522.MI_OK {
        print("Card detected")
    } else {
        sleep(1)
        continue
    }

    // Get the UID of the card
    let (statusUUID, uid) = rc522.anticoll()

    // If we have the UID, continue
    guard statusUUID == rc522.MI_OK else { break }

    // Print UID
    print("Card read UID: \(uid[0]), \(uid[1]), \(uid[2]), \(uid[3])")

    // This is the default key for authentication
    let key: [Byte] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]

    // Select the scanned tag
    rc522.selectTag(serNum: uid)

    /*
    Read.py

    // Authenticate
    let statusAuth = rc522.auth(authMode: rc522.PICC_AUTHENT1A, blockAddr: 8, sectorkey: key, serNum: uid)

    // Check if authenticated
    if statusAuth == rc522.MI_OK {
        rc522.read(blockAddr: 8)
        rc522.stopCrypto()
    } else {
        print("Authentication error")
    }
    */

    /*
    Dump.py
    */
    rc522.dumpClassic1K(key: key, uid: uid)

    rc522.stopCrypto()


    /*
    Write.py

    // Authenticate
    let statusAuth = rc522.auth(authMode: rc522.PICC_AUTHENT1A, blockAddr: 8, sectorkey: key, serNum: uid)
    print("\n")    

    // Check if authenticated
    if statusAuth != rc522.MI_OK {
        print("Authentication error")
        continue
    }

    print("Sector 8 looked like this:")
    rc522.read(blockAddr: 8)
    print("\n")

    print("Sector 8 will now be filled with 0xFF:")
    // Write the data
    rc522.write(blockAddr: 8, writeData: Array(repeating: (0xFF as Byte), count: 16))
    print("\n")

    print("It now looks like this:")
    // Check to see if it was written
    rc522.read(blockAddr: 8)
    print("\n")

    print("Now we fill it with 0x00:")
    rc522.write(blockAddr: 8, writeData: Array(repeating: (0x00 as Byte), count: 16))
    print("\n")

    print("It is now empty:")
    // Check to see if it was written
    rc522.read(blockAddr: 8)
    print("\n")

    // Stop    
    rc522.stopCrypto()
    */

    /*
    // Write NDEF
    guard rc522.auth(authMode: rc522.PICC_AUTHENT1A, blockAddr: 4, sectorkey: key, serNum: uid) == rc522.MI_OK else {
        print("Error reading block 4")
        break
    }

    print("\nBlock 4 looked like this:")
    rc522.read(blockAddr: 4)
    print("\n")

    print("Writing NDEF message to block 4")
    rc522.write(blockAddr: 4, writeData: [0x00, 0x00, 0x03, 0x11, 0xD1, 0x01, 0x0D, 0x55, 0x01, 0x61, 0x64, 0x61, 0x66, 0x72, 0x75, 0x69])
    print("\n")

    print("It now looks like this:")
    rc522.read(blockAddr: 4)
    print("\n")

    guard rc522.auth(authMode: rc522.PICC_AUTHENT1A, blockAddr: 5, sectorkey: key, serNum: uid) == rc522.MI_OK else {
        print("Error reading block 5")
        break
    }

    print("\nBlock 5 looked like this:")
    rc522.read(blockAddr: 5)
    print("\n")

    print("Writing NDEF message to block 5")
    rc522.write(blockAddr: 5, writeData: [0x74, 0x2E, 0x63, 0x6F, 0x6D, 0xFE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    print("\n")

    print("It now looks like this:")
    rc522.read(blockAddr: 5)
    print("\n")

    guard rc522.auth(authMode: rc522.PICC_AUTHENT1A, blockAddr: 6, sectorkey: key, serNum: uid) == rc522.MI_OK else {
        print("Error reading block 6")
        break
    }

    print("\nBlock 6 looked like this:")
    rc522.read(blockAddr: 6)
    print("\n")

    print("Writing NDEF message to block 6")
    rc522.write(blockAddr: 6, writeData: Array(repeating: (0x00 as Byte), count: 16))
    print("\n")

    print("It now looks like this:")
    rc522.read(blockAddr: 6)
    print("\n")

    rc522.stopCrypto()
    */
}

dispatchMain()
