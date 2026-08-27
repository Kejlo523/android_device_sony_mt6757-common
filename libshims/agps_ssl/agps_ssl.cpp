/*
 * Sony's Oreo mtk_agpsd asks BoringSSL for the obsolete SSLv3 method.
 * Android 10 deliberately removed that entry point, but still exposes the
 * protocol-negotiating TLS client method with the same ABI.  SUPL uses the
 * client side only; keep the server alias as a defensive compatibility shim.
 */

struct ssl_method_st;

extern "C" const ssl_method_st* TLS_client_method();
extern "C" const ssl_method_st* TLS_server_method();

extern "C" const ssl_method_st* SSLv3_client_method() {
    return TLS_client_method();
}

extern "C" const ssl_method_st* SSLv3_server_method() {
    return TLS_server_method();
}
