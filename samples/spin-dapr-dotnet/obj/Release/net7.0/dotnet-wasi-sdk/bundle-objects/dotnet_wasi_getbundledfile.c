#include <string.h>

int mono_wasm_add_assembly(const char* name, const unsigned char* data, unsigned int size);

extern const unsigned char SpinDontetDapr_dll_70EAE5EE[];
extern const int SpinDontetDapr_dll_70EAE5EE_len;
extern const unsigned char System_Collections_dll_AF6D9997[];
extern const int System_Collections_dll_AF6D9997_len;
extern const unsigned char System_Private_CoreLib_dll_9DB64A63[];
extern const int System_Private_CoreLib_dll_9DB64A63_len;
extern const unsigned char System_Console_dll_E7DB2DA0[];
extern const int System_Console_dll_E7DB2DA0_len;
extern const unsigned char System_Memory_dll_00248EFF[];
extern const int System_Memory_dll_00248EFF_len;
extern const unsigned char System_Private_Runtime_InteropServices_JavaScript_dll_7BA11F5C[];
extern const int System_Private_Runtime_InteropServices_JavaScript_dll_7BA11F5C_len;
extern const unsigned char System_Threading_dll_E1E52C28[];
extern const int System_Threading_dll_E1E52C28_len;
extern const unsigned char System_Runtime_InteropServices_dll_BBE50287[];
extern const int System_Runtime_InteropServices_dll_BBE50287_len;
extern const unsigned char System_Runtime_dll_A26A9722[];
extern const int System_Runtime_dll_A26A9722_len;
extern const unsigned char System_Private_Uri_dll_CA17AE62[];
extern const int System_Private_Uri_dll_CA17AE62_len;
extern const unsigned char System_Net_Primitives_dll_C5F9E818[];
extern const int System_Net_Primitives_dll_C5F9E818_len;
extern const unsigned char Microsoft_Win32_Primitives_dll_252E8074[];
extern const int Microsoft_Win32_Primitives_dll_252E8074_len;
extern const unsigned char System_Collections_NonGeneric_dll_8D99DECA[];
extern const int System_Collections_NonGeneric_dll_8D99DECA_len;
extern const unsigned char System_Diagnostics_Tracing_dll_57703958[];
extern const int System_Diagnostics_Tracing_dll_57703958_len;
extern const unsigned char Fermyon_Spin_Sdk_dll_1A3F1F48[];
extern const int Fermyon_Spin_Sdk_dll_1A3F1F48_len;
extern const unsigned char System_Net_Http_dll_66E89C80[];
extern const int System_Net_Http_dll_66E89C80_len;
extern const unsigned char System_Net_Security_dll_768D4E4B[];
extern const int System_Net_Security_dll_768D4E4B_len;
extern const unsigned char System_Security_Cryptography_dll_143D7D5D[];
extern const int System_Security_Cryptography_dll_143D7D5D_len;
extern const unsigned char System_Text_Encoding_Extensions_dll_1A33998E[];
extern const int System_Text_Encoding_Extensions_dll_1A33998E_len;
extern const unsigned char System_Collections_Concurrent_dll_8C69425B[];
extern const int System_Collections_Concurrent_dll_8C69425B_len;
extern const unsigned char System_Runtime_Numerics_dll_2C79EA9D[];
extern const int System_Runtime_Numerics_dll_2C79EA9D_len;
extern const unsigned char System_Formats_Asn1_dll_F84ABF50[];
extern const int System_Formats_Asn1_dll_F84ABF50_len;
extern const unsigned char System_Diagnostics_DiagnosticSource_dll_3CA24B2B[];
extern const int System_Diagnostics_DiagnosticSource_dll_3CA24B2B_len;
extern const unsigned char System_Threading_Thread_dll_E274918D[];
extern const int System_Threading_Thread_dll_E274918D_len;
extern const unsigned char System_Collections_Immutable_dll_94261DBB[];
extern const int System_Collections_Immutable_dll_94261DBB_len;
extern const unsigned char System_Linq_dll_5300B979[];
extern const int System_Linq_dll_5300B979_len;
extern const unsigned char System_Numerics_Vectors_dll_B2FD5EE1[];
extern const int System_Numerics_Vectors_dll_B2FD5EE1_len;

const unsigned char* dotnet_wasi_getbundledfile(const char* name, int* out_length) {
  return NULL;
}

void dotnet_wasi_registerbundledassemblies() {
  mono_wasm_add_assembly ("SpinDontetDapr.dll", SpinDontetDapr_dll_70EAE5EE, SpinDontetDapr_dll_70EAE5EE_len);
  mono_wasm_add_assembly ("System.Collections.dll", System_Collections_dll_AF6D9997, System_Collections_dll_AF6D9997_len);
  mono_wasm_add_assembly ("System.Private.CoreLib.dll", System_Private_CoreLib_dll_9DB64A63, System_Private_CoreLib_dll_9DB64A63_len);
  mono_wasm_add_assembly ("System.Console.dll", System_Console_dll_E7DB2DA0, System_Console_dll_E7DB2DA0_len);
  mono_wasm_add_assembly ("System.Memory.dll", System_Memory_dll_00248EFF, System_Memory_dll_00248EFF_len);
  mono_wasm_add_assembly ("System.Private.Runtime.InteropServices.JavaScript.dll", System_Private_Runtime_InteropServices_JavaScript_dll_7BA11F5C, System_Private_Runtime_InteropServices_JavaScript_dll_7BA11F5C_len);
  mono_wasm_add_assembly ("System.Threading.dll", System_Threading_dll_E1E52C28, System_Threading_dll_E1E52C28_len);
  mono_wasm_add_assembly ("System.Runtime.InteropServices.dll", System_Runtime_InteropServices_dll_BBE50287, System_Runtime_InteropServices_dll_BBE50287_len);
  mono_wasm_add_assembly ("System.Runtime.dll", System_Runtime_dll_A26A9722, System_Runtime_dll_A26A9722_len);
  mono_wasm_add_assembly ("System.Private.Uri.dll", System_Private_Uri_dll_CA17AE62, System_Private_Uri_dll_CA17AE62_len);
  mono_wasm_add_assembly ("System.Net.Primitives.dll", System_Net_Primitives_dll_C5F9E818, System_Net_Primitives_dll_C5F9E818_len);
  mono_wasm_add_assembly ("Microsoft.Win32.Primitives.dll", Microsoft_Win32_Primitives_dll_252E8074, Microsoft_Win32_Primitives_dll_252E8074_len);
  mono_wasm_add_assembly ("System.Collections.NonGeneric.dll", System_Collections_NonGeneric_dll_8D99DECA, System_Collections_NonGeneric_dll_8D99DECA_len);
  mono_wasm_add_assembly ("System.Diagnostics.Tracing.dll", System_Diagnostics_Tracing_dll_57703958, System_Diagnostics_Tracing_dll_57703958_len);
  mono_wasm_add_assembly ("Fermyon.Spin.Sdk.dll", Fermyon_Spin_Sdk_dll_1A3F1F48, Fermyon_Spin_Sdk_dll_1A3F1F48_len);
  mono_wasm_add_assembly ("System.Net.Http.dll", System_Net_Http_dll_66E89C80, System_Net_Http_dll_66E89C80_len);
  mono_wasm_add_assembly ("System.Net.Security.dll", System_Net_Security_dll_768D4E4B, System_Net_Security_dll_768D4E4B_len);
  mono_wasm_add_assembly ("System.Security.Cryptography.dll", System_Security_Cryptography_dll_143D7D5D, System_Security_Cryptography_dll_143D7D5D_len);
  mono_wasm_add_assembly ("System.Text.Encoding.Extensions.dll", System_Text_Encoding_Extensions_dll_1A33998E, System_Text_Encoding_Extensions_dll_1A33998E_len);
  mono_wasm_add_assembly ("System.Collections.Concurrent.dll", System_Collections_Concurrent_dll_8C69425B, System_Collections_Concurrent_dll_8C69425B_len);
  mono_wasm_add_assembly ("System.Runtime.Numerics.dll", System_Runtime_Numerics_dll_2C79EA9D, System_Runtime_Numerics_dll_2C79EA9D_len);
  mono_wasm_add_assembly ("System.Formats.Asn1.dll", System_Formats_Asn1_dll_F84ABF50, System_Formats_Asn1_dll_F84ABF50_len);
  mono_wasm_add_assembly ("System.Diagnostics.DiagnosticSource.dll", System_Diagnostics_DiagnosticSource_dll_3CA24B2B, System_Diagnostics_DiagnosticSource_dll_3CA24B2B_len);
  mono_wasm_add_assembly ("System.Threading.Thread.dll", System_Threading_Thread_dll_E274918D, System_Threading_Thread_dll_E274918D_len);
  mono_wasm_add_assembly ("System.Collections.Immutable.dll", System_Collections_Immutable_dll_94261DBB, System_Collections_Immutable_dll_94261DBB_len);
  mono_wasm_add_assembly ("System.Linq.dll", System_Linq_dll_5300B979, System_Linq_dll_5300B979_len);
  mono_wasm_add_assembly ("System.Numerics.Vectors.dll", System_Numerics_Vectors_dll_B2FD5EE1, System_Numerics_Vectors_dll_B2FD5EE1_len);
}

