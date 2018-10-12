./gum-tests \
    -s /Core/X86Writer/call_indirect_label \
    -s /Core/X86Writer/lock_inc_dec_imm32_ptr \
    -s /Core/ArmWriter/ldr_u32 \
    -s /Core/ArmWriter/ldr_pc_u32 \
    -s /Core/ThumbWriter/ldr_u32 \
    -s /Core/Arm64Writer/ldr_x_address \
    -s /Core/Arm64Writer/ldr_d_address \
    -s /GumJS/Script/function_can_be_replaced#DUK \
    -s /GumJS/Script/interceptor_handles_invalid_arguments#DUK \
    -s /GumJS/Script/memory_can_be_copied#DUK \
    -s /GumJS/Script/invalid_read_results_in_exception#DUK \
    -s /GumJS/Script/invalid_write_results_in_exception#DUK \
    -s /GumJS/Script/invalid_read_write_execute_results_in_exception#DUK \
    -s /GumJS/Script/memory_scan_handles_unreadable_memory#DUK \
    -s /GumJS/Script/native_function_can_be_invoked#DUK \
    -s /GumJS/Script/native_function_can_be_intercepted_when_thread_is_ignored#DUK \
    -s /GumJS/Script/native_function_should_implement_call_and_apply#DUK \
    -s /GumJS/Script/system_function_can_be_invoked#DUK \
    -s /GumJS/Script/native_function_crash_results_in_exception#DUK \
    -s /GumJS/Script/nested_native_function_crash_is_handled_gracefully#DUK \
    -s /GumJS/Script/variadic_native_function_can_be_invoked#DUK \
    -s /GumJS/Script/native_callback_can_be_invoked#DUK \
    -s /GumJS/Script/native_callback_memory_should_be_eagerly_reclaimed#DUK \
    -s /GumJS/Script/instruction_can_be_parsed#DUK \
    -s /GumJS/Script/script_can_be_compiled_to_bytecode#DUK \
    -s /GumJS/Script/script_memory_usage#DUK \
    -s /GumJS/Script/source_maps_should_be_supported_for_our_runtime#DUK \

