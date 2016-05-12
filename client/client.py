import serial
import crcmod
import time
import bitstring
import struct
from threading import Thread


ser = serial.Serial('/dev/ttyUSB0', 112500, timeout=None)
crc = crcmod.mkCrcFun(0x18005, initCrc=0 ,rev=False)

def transmit(data, crc = None):
	ser.write(data)
	if crc is not None:
		ser.write(crc)

def receive(number):
	return ser.read(number)



key_high = '000102030405060708090a0b0c0d0e0f'
key_low  = '101112131415161718191a1b1c1d1e1f'
# key_high = '1f1e1d1c1b1a19181716151413121110'
# key_low  = '0f0e0d0c0b0a09080706050403020100'
iv       = '00000000000000000000000000000000'

key_high_bytes = key_high.decode('hex')
key_low_bytes  = key_low.decode('hex')
iv_bytes       = iv.decode('hex')

key_high_crc = struct.pack('>H', crc(key_high_bytes))
key_low_crc  = struct.pack('>H', crc(key_low_bytes))
iv_crc       = struct.pack('>H', crc(iv_bytes))

while True:
	transmit(key_high_bytes, key_high_crc)
	if receive(1) == 'A':
		break

while True:
	transmit(key_low_bytes, key_low_crc)
	if receive(1) == 'A':
		break

while True:
	transmit(iv_bytes, iv_crc)
	if receive(1) == 'A':
		break

with open('data256', 'rb') as plaintext_file, open('data256.out', 'wb') as ciphertext_file:
	plaintext_bytes      = plaintext_file.read(16)
	plaintext_bytes_next = plaintext_file.read(16)
	plaintext_crc        = struct.pack('>H', crc(plaintext_bytes))
	
	while True:
		transmit(plaintext_bytes, plaintext_crc)
		if receive(1) == 'A':
			break

	if plaintext_bytes_next == '':
		transmit('F')
	else:
		transmit('A')

	while True:
		plaintext_bytes      = plaintext_bytes_next
		plaintext_bytes_next = plaintext_file.read(16)
		
		#end of file
		if plaintext_bytes == '':
			break

		plaintext_crc = struct.pack('>H', crc(plaintext_bytes))

		#handle retransmissions
		while True:
			transmitter_thread_block_crc = Thread(target=transmit, args=(plaintext_bytes, plaintext_crc,))
			transmitter_thread_block_crc.start()
	
			ciphertext_bytes = receive(16)
			ciphertext_crc   = receive(2)
	
			transmitter_thread_block_crc.join()
	
			ack_to_send = None
			transmit_success = False
			if ciphertext_crc == struct.pack('>H', crc(ciphertext_bytes)):
				transmit_success = True
				if plaintext_bytes_next == '':
					ack_to_send = 'F'
				else:
					ack_to_send = 'A'
			else:
				ack_to_send = 'N'

			transmitter_thread_ack = Thread(target=transmit, args=(ack_to_send,))
			transmitter_thread_ack.start()

			ciphertext_ack = receive(1)

			transmitter_thread_ack.join()

			if transmit_success and ciphertext_ack == 'A':
				ciphertext_file.write(ciphertext_bytes)
				break			

	while True:
		ciphertext_bytes = receive(16)
		ciphertext_crc   = receive(2)

		if ciphertext_crc == struct.pack('>H', crc(ciphertext_bytes)):
			transmit('F')
			ciphertext_file.write(ciphertext_bytes)
			break
		else:
			transmit('N')