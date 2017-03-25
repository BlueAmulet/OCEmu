local address, _, tier = ...

-- data component
local mai = {}
local obj = {}

mai.crc32 = {direct = true, doc = "function(data:string):string -- Computes CRC-32 hash of the data. Result is binary data."}
function obj.crc32(data)
	--STUB
	cprint("data.crc32", data)
end

mai.decode64 = {direct = true, doc = "function(data:string):string -- Applies base64 decoding to the data."}
function obj.decode64(data)
	--STUB
	cprint("data.decode64", data)
end

mai.encode64 = {direct = true, doc = "function(data:string):string -- Applies base64 encoding to the data."}
function obj.encode64(data)
	--STUB
	cprint("data.encode64", data)
end

mai.md5 = {direct = true, doc = "function(data:string[, hmacKey:string]):string -- Computes MD5 hash of the data. Result is binary data."}
function obj.md5(data, hmacKey)
	--STUB
	cprint("data.md5", data, hmacKey)
end

mai.sha256 = {direct = true, doc = "function(data:string[, hmacKey:string]):string -- Computes SHA2-256 hash of the data. Result is binary data."}
function obj.sha256(data, hmacKey)
	--STUB
	cprint("data.sha256", data, hmacKey)
end

mai.deflate = {direct = true, doc = "function(data:string):string -- Applies deflate compression to the data."}
function obj.deflate(data)
	--STUB
	cprint("data.deflate", data)
end

mai.inflate = {direct = true, doc = "function(data:string):string -- Applies inflate decompression to the data."}
function obj.inflate(data)
	--STUB
	cprint("data.inflate", data)
end

mai.getLimit = {direct = true, doc = "function():number -- The maximum size of data that can be passed to other functions of the card."}
function obj.getLimit()
	--STUB
	cprint("data.getLimit")
end

if tier >= 2 then

mai.random = {direct = true, doc = "function(len:number):string -- Generates secure random binary data."}
function obj.random(len)
	--STUB
	cprint("data.random", len)
end

mai.decrypt = {direct = true, doc = "function(data:string, key:string, iv:string):string -- Decrypt data with AES."}
function obj.decrypt(data, key, iv)
	--STUB
	cprint("data.decrypt", data, key, iv)
end

mai.encrypt = {direct = true, doc = "function(data:string, key: string, iv:string):string -- Encrypt data with AES. Result is binary data."}
function obj.encrypt(data, key, iv)
	--STUB
	cprint("data.encrypt", data, key, iv)
end

if tier >= 3 then

mai.ecdsa = {direct = true, doc = "function(data:string, key:userdata[, sig:string]):string or boolean -- Signs or verifies data."}
function obj.ecdsa(data, key, sig)
	--STUB
	cprint("data.ecdsa", data, key, sig)
end

mai.ecdh = {direct = true, doc = "function(priv:userdata, pub:userdata):string -- Generates a shared key. ecdh(a.priv, b.pub) == ecdh(b.priv, a.pub)"}
function obj.ecdh(priv, pub)
	--STUB
	cprint("data.ecdh", priv, pub)
end

mai.generateKeyPair = {direct = true, doc = "function([bitLen:number]):userdata, userdata -- Generates key pair. Returns: public, private keys. Allowed key lengths: 256, 384 bits."}
function obj.generateKeyPair(bitLen)
	--STUB
	cprint("data.generateKeyPair", bitLen)
end

mai.deserializeKey = {direct = true, doc = "function(data:string, type:string):userdata -- Restores key from its string representation."}
function obj.deserializeKey(data, type)
	--STUB
	cprint("data.deserializeKey", data, type)
end

end -- tier >= 3
end -- tier >= 2

return obj,nil,mai
