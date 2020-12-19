/* The following function is only for the linklib. */
bool glue_of_init(unsigned int version, struct of_libc *libc, FILE **sF);
void *glue_of_alloc(size_t count, size_t size);
void *glue_of_alloc_zeroed(size_t count, size_t size);
void *glue_of_realloc(void *pointer, size_t count, size_t size);
uint32_t *glue_of_hash_seed_ref(void);
OFStdIOStream **glue_of_stdin_ref(void);
OFStdIOStream **glue_of_stdout_ref(void);
OFStdIOStream **glue_of_stderr_ref(void);
void glue_of_logv(OFConstantString *format, va_list arguments);
int glue_of_application_main(int *argc, char ***argv, id <OFApplicationDelegate> delegate);
const char *glue_of_http_request_method_to_string(of_http_request_method_t method);
of_http_request_method_t glue_of_http_request_method_from_string(OFString *string);
OFString *glue_of_http_status_code_to_string(short code);
size_t glue_of_sizeof_type_encoding(const char *type);
size_t glue_of_alignof_type_encoding(const char *type);
of_string_encoding_t glue_of_string_parse_encoding(OFString *string);
OFString *glue_of_string_name_of_encoding(of_string_encoding_t encoding);
size_t glue_of_string_utf8_encode(of_unichar_t c, char *UTF8);
ssize_t glue_of_string_utf8_decode(const char *UTF8, size_t len, of_unichar_t *c);
size_t glue_of_string_utf16_length(const of_char16_t *string);
size_t glue_of_string_utf32_length(const of_char32_t *string);
OFString *glue_of_zip_archive_entry_version_to_string(uint16_t version);
OFString *glue_of_zip_archive_entry_compression_method_to_string(uint16_t compressionMethod);
size_t glue_of_zip_archive_entry_extra_field_find(OFData *extraField, uint16_t tag, uint16_t *size);
void glue_of_pbkdf2(const of_pbkdf2_parameters_t *param);
void glue_of_salsa20_8_core(uint32_t *buffer);
void glue_of_scrypt_block_mix(uint32_t *output, const uint32_t *input, size_t blockSize);
void glue_of_scrypt_romix(uint32_t *buffer, size_t blockSize, size_t costFactor, uint32_t *tmp);
void glue_of_scrypt(const of_scrypt_parameters_t *param);
const char *glue_of_strptime(const char *buf, const char *fmt, struct tm *tm, int16_t *tz);
void glue_of_socket_address_parse_ip(of_socket_address_t *address, OFString *IP, uint16_t port);
void glue_of_socket_address_parse_ipv4(of_socket_address_t *address, OFString *IP, uint16_t port);
void glue_of_socket_address_parse_ipv6(of_socket_address_t *address, OFString *IP, uint16_t port);
void glue_of_socket_address_ipx(of_socket_address_t *address, const unsigned char *node, uint32_t network, uint16_t port);
bool glue_of_socket_address_equal(const of_socket_address_t *address1, const of_socket_address_t *address2);
unsigned long glue_of_socket_address_hash(const of_socket_address_t *address);
OFString *glue_of_socket_address_ip_string(const of_socket_address_t *address, uint16_t *port);
void glue_of_socket_address_set_port(of_socket_address_t *address, uint16_t port);
uint16_t glue_of_socket_address_get_port(const of_socket_address_t *address);
void glue_of_socket_address_set_ipx_network(of_socket_address_t *address, uint32_t network);
uint32_t glue_of_socket_address_get_ipx_network(const of_socket_address_t *address);
void glue_of_socket_address_set_ipx_node(of_socket_address_t *address, const unsigned char *node);
void glue_of_socket_address_get_ipx_node(const of_socket_address_t *address, unsigned char *node);
OFString *glue_of_dns_class_to_string(of_dns_class_t DNSClass);
OFString *glue_of_dns_record_type_to_string(of_dns_record_type_t recordType);
of_dns_class_t glue_of_dns_class_parse(OFString *string);
of_dns_record_type_t glue_of_dns_record_type_parse(OFString *string);