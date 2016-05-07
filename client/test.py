import serial
import crcmod
import time
import bitstring
from threading import Thread


# crc = crcmod.mkCrcFun(0x18005, initCrc=0 ,rev=False)
# hex(crc(b'\x12\x34\x56\x78'))
# data_hex = '0x000102030405060708090a0b0c0d0e0f'


crc = crcmod.mkCrcFun(0x18005, initCrc=0 ,rev=False)

data_hex = '0x30313233343536373839616263646566'
data_bytes = bitstring.BitArray(data_hex).bytes
print data_bytes


crc_hex = hex(crc(data_bytes))
print crc_hex


block_crc = bitstring.pack('hex:128, hex:16', data_hex, crc_hex).bytes
print block_crc



# ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=None)
ser = serial.Serial('/dev/ttyUSB0', 112500, timeout=None)

def transmit(data):
	ser.write(data)

def receive(number):
	print ser.read(number)

ser.write(block_crc)
print ser.read(1)
ser.write('A')

for i in xrange(10000):
	print i
	block_sender   = Thread(target=transmit, args=(block_crc,))
	ack_sender     = Thread(target=transmit, args=('A',))

	block_sender.start()
	ack_received = receive(1)
	block_sender.join()

	ack_sender.start()
	block_received = receive(18)
	ack_sender.join()

	# print block_received
	# print ack_received
	# print block_received

	# if ack_received != 'A':
		# print 'error'
		# time.sleep(1)
