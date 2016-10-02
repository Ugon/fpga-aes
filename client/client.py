import re
import serial
import crcmod
import struct
import argparse

from threading import Thread

def check_key(string):
	if len(string) != 64:
		raise argparse.ArgumentTypeError("invalid hex key value (length not equal to 64)")
	elif not re.compile('[0-9a-fA-F]*$').match(string):
		raise argparse.ArgumentTypeError("invalid hex key value (non-hex digit)")
	return string

def check_iv(string):
	if len(string) != 32:
		raise argparse.ArgumentTypeError("invalid hex iv value (length not equal to 32)")
	elif not re.compile('[0-9a-fA-F]*$').match(string):
		raise argparse.ArgumentTypeError("invalid hex iv value (non-hex digit)")
	return string	

parser = argparse.ArgumentParser(description='aes-256-cbc encryption using FPGA')

parser.add_argument('-d'  , action='store_true', dest='decode', required=False,                 help='decode')
parser.add_argument('-in' , metavar='filename' , dest='input' , required=True ,                 help='the input filename')
parser.add_argument('-out', metavar='filename' , dest='output', required=True ,                 help='the output filename')
parser.add_argument('-K'  , metavar='key'      , dest='key'   , required=True , type=check_key, help='the actual key to use: this must be represented as a string comprised only of hex digits.')
parser.add_argument('-iv' , metavar='IV'       , dest='iv'    , required=True , type=check_iv , help='the actual IV to use: this must be represented as a string comprised only of hex digits.')

args = parser.parse_args()

key_high        = args.key[0:32]
key_low         = args.key[32:64]
iv              = args.iv
input_filename  = args.input
output_filename = args.output
decode          = args.decode

ser = serial.Serial('/dev/ttyUSB0', 112500, timeout=None)
crc = crcmod.mkCrcFun(0x18005, initCrc=0 ,rev=False)

def transmit(data, crc = None):
	ser.write(data)
	if crc is not None:
		ser.write(crc)

def receive(number):
	return ser.read(number)

key_high_bytes = key_high.decode('hex')
key_low_bytes  = key_low.decode('hex')
iv_bytes       = iv.decode('hex')

key_high_crc = struct.pack('>H', crc(key_high_bytes))
key_low_crc  = struct.pack('>H', crc(key_low_bytes))
iv_crc       = struct.pack('>H', crc(iv_bytes))

#transmit choice
while True:
	transmit('D' if decode else 'E')
	if receive(1) == 'A':
		break

# transmit key high bytes
while True:
	transmit(key_high_bytes, key_high_crc)
	if receive(1) == 'A':
		break

# transmit key low bytes
while True:
	transmit(key_low_bytes, key_low_crc)
	if receive(1) == 'A':
		break

# transmit initialization vector
while True:
	transmit(iv_bytes, iv_crc)
	if receive(1) == 'A':
		break

with open(input_filename, 'rb') as input_file, open(output_filename, 'wb') as output_file:

	if not decode:
		def read_block(f):
			block = f.read(16)
			missing = 16 - len(block)
			block = block + missing * struct.pack('B', missing) # apply padding
			end_of_file = missing > 0
			return block, end_of_file

		plaintext_bytes, end_of_file = read_block(input_file)
		plaintext_crc                = struct.pack('>H', crc(plaintext_bytes))
		
		# transmit first block
		while True:
			transmit(plaintext_bytes, plaintext_crc)
			if receive(1) == 'A':
				break
	
		# transmit first ack
		transmit('F' if end_of_file else 'A')
	
		# exchange middle blocks
		while not end_of_file:
			plaintext_bytes, end_of_file = read_block(input_file)
			plaintext_crc                = struct.pack('>H', crc(plaintext_bytes))
	
			#handle retransmissions
			while True:
				# exchange blocks
				transmitter_thread_block_crc = Thread(target=transmit, args=(plaintext_bytes, plaintext_crc,))
				transmitter_thread_block_crc.start()
		
				ciphertext_bytes = receive(16)
				ciphertext_crc   = receive(2)
				receive_success  = ciphertext_crc == struct.pack('>H', crc(ciphertext_bytes))
		
				transmitter_thread_block_crc.join()
		
				# determine ack to send
				success_ack      = 'F' if end_of_file else 'A'
				ack_to_send      = success_ack if receive_success else 'N'
	
				# exchange acks
				transmitter_thread_ack = Thread(target=transmit, args=(ack_to_send,))
				transmitter_thread_ack.start()
	
				ciphertext_ack   = receive(1)
				transmit_success = ciphertext_ack == 'A'
	
				transmitter_thread_ack.join()
	
				# if exchange successful then break else retransmission
				if receive_success and transmit_success:
					output_file.write(ciphertext_bytes)
					break			
	
		# receive last block
		while True:
			# receive block
			ciphertext_bytes = receive(16)
			ciphertext_crc   = receive(2)
			receive_success  = ciphertext_crc == struct.pack('>H', crc(ciphertext_bytes))
	
			# transmit ack
			transmit('A' if receive_success else 'N')
			
			# if receive successful then break
			if receive_success:
				output_file.write(ciphertext_bytes)
				break

	else:
		def read_block(f):
			block = f.read(16)
			end_of_file = len(block) < 16
			return block, end_of_file

		plaintext_bytes, end_of_file           = read_block(input_file)
		next_plaintext_bytes, next_end_of_file = read_block(input_file)
		plaintext_crc                          = struct.pack('>H', crc(plaintext_bytes))
		
		# transmit first block
		while True:
			transmit(plaintext_bytes, plaintext_crc)
			if receive(1) == 'A':
				break
		# transmit first ack
		transmit('F' if next_end_of_file else 'A')
		# exchange middle blocks
		while not next_end_of_file and not end_of_file:
			plaintext_bytes, end_of_file           = next_plaintext_bytes, next_end_of_file
			next_plaintext_bytes, next_end_of_file = read_block(input_file)
			plaintext_crc                          = struct.pack('>H', crc(plaintext_bytes))

			#handle retransmissions
			while True:
				# exchange blocks
				transmitter_thread_block_crc = Thread(target=transmit, args=(plaintext_bytes, plaintext_crc,))
				transmitter_thread_block_crc.start()
		
				ciphertext_bytes = receive(16)
				ciphertext_crc   = receive(2)
				receive_success  = ciphertext_crc == struct.pack('>H', crc(ciphertext_bytes))
		
				transmitter_thread_block_crc.join()
		
				# determine ack to send
				success_ack      = 'F' if next_end_of_file else 'A'
				ack_to_send      = success_ack if receive_success else 'N'

				# exchange acks
				transmitter_thread_ack = Thread(target=transmit, args=(ack_to_send,))
				transmitter_thread_ack.start()
				ciphertext_ack   = receive(1)
				transmit_success = ciphertext_ack == 'A'
				transmitter_thread_ack.join()

				# if exchange successful then break else retransmission
				if receive_success and transmit_success:
					output_file.write(ciphertext_bytes)
					break	

		# receive last block
		while True:
			# receive block
			ciphertext_bytes = receive(16)
			ciphertext_crc   = receive(2)
			receive_success  = ciphertext_crc == struct.pack('>H', crc(ciphertext_bytes))

			# transmit ack
			transmit('A' if receive_success else 'N')
			
			# if receive successful then break
			if receive_success:
				padding_length = struct.unpack('B', ciphertext_bytes[-1])[0] # remove padding
				ciphertext_bytes_no_padding = ciphertext_bytes[0: 16 - padding_length]
				output_file.write(ciphertext_bytes_no_padding)
				break