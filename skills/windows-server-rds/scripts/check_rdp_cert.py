import socket, ssl, hashlib, sys
from datetime import datetime
host, port = sys.argv[1], 3389
s = socket.create_connection((host, port), timeout=10)
# X.224 Connection Request con RDP_NEG_REQ pidiendo TLS
req = bytes([0x03,0x00,0x00,0x13, 0x0e,0xe0,0x00,0x00,0x00,0x00,0x00,
             0x01,0x00,0x08,0x00, 0x03,0x00,0x00,0x00])
s.sendall(req)
resp = s.recv(1024)
print("X.224 respuesta:", resp.hex())
if len(resp) >= 19 and resp[11] == 0x02:
    print("selectedProtocol =", int.from_bytes(resp[15:19], 'little'), "(1=TLS, 2=CredSSP/NLA)")
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
tls = ctx.wrap_socket(s, server_hostname="SRV-CLIENTE")
der = tls.getpeercert(binary_form=True)
cert = tls.getpeercert()
print("TLS:", tls.version())
print("SHA1 del cert servido:", hashlib.sha1(der).hexdigest().upper())
print("Subject:", cert)
tls.close()
