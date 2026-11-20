/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20260408 (32-bit version)
 * Copyright (c) 2000 - 2026 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of G:/EFI/OC/ACPI/SSDT-ALIBFix.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x0000006A (106)
 *     Revision         0x02
 *     Checksum         0xD8
 *     OEM ID           "ASUS"
 *     OEM Table ID     "ALIBFix"
 *     OEM Revision     0x00000001 (1)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20260408 (539362312)
 */
DefinitionBlock ("", "SSDT", 2, "ASUS", "ALIBFix", 0x00000001)
{
    External (_SB_.A026, MethodObj)    // 1 Arguments
    External (_SB_.XLIB, MethodObj)    // 2 Arguments

    Scope (\_SB)
    {
        Method (ALIB, 2, Serialized)
        {
            If ((Arg0 == One))
            {
                Local0 = DerefOf (Arg1 [0x02])
                A026 (Local0)
                Return (Zero)
            }

            Return (XLIB (Arg0, Arg1))
        }
    }
}

