# Integrate Charmed OAI RAN with an Ettus Research USRP Radio

This guide explains how to integrate Charmed OAI RAN with an Ettus Research USRP radio.

The OAI RAN DU charm expects the USRP radio to be connected to the host machine via USB 3. 

1. Deploy Charmed OAI RAN following the [how-to guide](deploy_oai_ran.md). Deploy the DU with the following configuration options that meets your requirements. Please check the [DU Configuration] to see the supported ranges. 
    * `simulation-mode`: `false`
    * `use-three-quarter-sampling`: `true`
    * `bandwidth`: `<your bandwidth>`
    * `frequency-band`: `<your frequency band>`
    * `sub-carrier-spacing`: `<your sub carrierspacing>`
    * `center-frequency`: `<your center frequency>`

2. Connect the USRP radio to the host machine via USB. The DU should automatically detect the USRP radio.

3. Validate the USRP radio is detected by the DU by looking at the DU logs:
    ```console
    kubectl logs du-0 -c du -n ran -f
    ```

    You should see the following log lines:
    ```
    2025-01-08T19:14:13.230Z [du] [HW]     Actual TX packet size: 1916
    2025-01-08T19:14:13.230Z [du] Using Device: Single USRP:
    2025-01-08T19:14:13.230Z [du]   Device: B-Series Device
    2025-01-08T19:14:13.230Z [du]   Mboard 0: B205mini
    2025-01-08T19:14:13.230Z [du]   RX Channel: 0
    2025-01-08T19:14:13.230Z [du]     RX DSP: 0
    2025-01-08T19:14:13.230Z [du]     RX Dboard: A
    2025-01-08T19:14:13.230Z [du]     RX Subdev: FE-RX1
    2025-01-08T19:14:13.230Z [du]   TX Channel: 0
    2025-01-08T19:14:13.230Z [du]     TX DSP: 0
    2025-01-08T19:14:13.230Z [du]     TX Dboard: A
    2025-01-08T19:14:13.230Z [du]     TX Subdev: FE-TX1
    2025-01-08T19:14:13.230Z [du] 
    2025-01-08T19:14:13.230Z [du] [HW]   Device timestamp: 1.171154...
    2025-01-08T19:14:13.230Z [du] [HW]   [RAU] has loaded USRP B200 device.
    2025-01-08T19:14:13.230Z [du] [PHY]   RU 0 Setting N_TA_offset to 600 samples (UL Freq 3904980, N_RB 106, mu 1)
    2025-01-08T19:14:13.230Z [du] [PHY]   Signaling main thread that RU 0 is ready, sl_ahead 6
    2025-01-08T19:14:13.230Z [du] [PHY]   RUs configured
    2025-01-08T19:14:13.230Z [du] [PHY]   init_eNB_afterRU() RC.nb_nr_inst:1
    2025-01-08T19:14:13.230Z [du] [PHY]   RC.nb_nr_CC[inst:0]:0x7f4daa200010
    2025-01-08T19:14:13.230Z [du] [PHY]   L1 configured without analog beamforming
    2025-01-08T19:14:13.230Z [du] [PHY]   [gNB 0]About to wait for gNB to be configured
    2025-01-08T19:14:13.230Z [du] [PHY]   Initialise nr transport
    2025-01-08T19:14:13.350Z [du] [PHY]   Mapping RX ports from 1 RUs to gNB 0
    2025-01-08T19:14:13.550Z [du] [PHY]   gNB->num_RU:1
    2025-01-08T19:14:13.550Z [du] [PHY]   Attaching RU 0 antenna 0 to gNB antenna 0
    2025-01-08T19:14:13.550Z [du] [UTIL]   threadCreate() for Tpool0_-1: creating thread with affinity ffffffff, priority 97
    2025-01-08T19:14:13.550Z [du] [UTIL]   threadCreate() for Tpool1_-1: creating thread with affinity ffffffff, priority 97
    2025-01-08T19:14:13.550Z [du] [UTIL]   threadCreate() for Tpool2_-1: creating thread with affinity ffffffff, priority 97
    2025-01-08T19:14:13.551Z [du] [UTIL]   threadCreate() for Tpool3_-1: creating thread with affinity ffffffff, priority 97
    2025-01-08T19:14:13.555Z [du] [UTIL]   threadCreate() for Tpool4_-1: creating thread with affinity ffffffff, priority 97
    2025-01-08T19:14:13.557Z [du] [UTIL]   threadCreate() for Tpool5_-1: creating thread with affinity ffffffff, priority 97
    2025-01-08T19:14:13.560Z [du] [UTIL]   threadCreate() for Tpool6_-1: creating thread with affinity ffffffff, priority 97
    2025-01-08T19:14:13.561Z [du] [UTIL]   threadCreate() for Tpool7_-1: creating thread with affinity ffffffff, priority 97
    2025-01-08T19:14:13.563Z [du] [UTIL]   threadCreate() for L1_rx_thread: creating thread with affinity ffffffff, priority 97
    2025-01-08T19:14:13.564Z [du] [UTIL]   threadCreate() for L1_tx_thread: creating thread with affinity ffffffff, priority 97
    2025-01-08T19:14:13.566Z [du] [UTIL]   threadCreate() for L1_stats: creating thread with affinity ffffffff, priority 1
    2025-01-08T19:14:13.570Z [du] setup_RU_buffers: frame_parms = 0x7f4daa47d010
    2025-01-08T19:14:13.572Z [du] waiting for sync (ru_thread,-1/0x5cb671c400a8,0x5cb6724ef580,0x5cb6724ef540)
    2025-01-08T19:14:13.572Z [du] RC.ru_mask:00
    2025-01-08T19:14:13.572Z [du] ALL RUs READY!
    2025-01-08T19:14:13.572Z [du] RC.nb_RU:1
    2025-01-08T19:14:13.572Z [du] ALL RUs ready - init gNBs
    2025-01-08T19:14:13.572Z [du] Not NFAPI mode - call init_eNB_afterRU()
    2025-01-08T19:14:13.572Z [du] shlib_path libdfts.so
    2025-01-08T19:14:13.572Z [du] [LOADER] library libdfts.so successfully loaded
    2025-01-08T19:14:13.572Z [du] shlib_path libldpc.so
    2025-01-08T19:14:13.572Z [du] [LOADER] library libldpc.so successfully loaded
    2025-01-08T19:14:13.572Z [du] shlib_path libldpc.so
    2025-01-08T19:14:13.572Z [du] [LOADER] library libldpc.so has been loaded previously, reloading function pointers
    2025-01-08T19:14:13.572Z [du] [LOADER] library libldpc.so successfully loaded
    2025-01-08T19:14:13.572Z [du] waiting for sync (L1_stats_thread,-1/0x5cb671c400a8,0x5cb6724ef580,0x5cb6724ef540)
    2025-01-08T19:14:13.572Z [du] ALL RUs ready - ALL gNBs ready
    2025-01-08T19:14:13.572Z [du] Sending sync to all threads
    2025-01-08T19:14:13.572Z [du] Entering ITTI signals handler
    2025-01-08T19:14:13.572Z [du] TYPE <CTRL-C> TO TERMINATE
    2025-01-08T19:14:13.572Z [du] got sync (L1_stats_thread)
    2025-01-08T19:14:13.572Z [du] got sync (ru_thread)
    2025-01-08T19:14:14.059Z [du] [HW]   current pps at 2.000000, starting streaming at 3.000000
    2025-01-08T19:14:14.059Z [du] [PHY]   RU 0 rf device ready
    2025-01-08T19:14:14.059Z [du] [PHY]   RU 0 RF started cpu_meas_enabled 0
    2025-01-08T19:14:14.059Z [du] [PHY]   Command line parameters for OAI UE: -C 3924060000 -r 106 --numerology 1 --ssb 530 -E
    2025-01-08T19:14:15.077Z [du] [NR_MAC]   Frame.Slot 384.0
    2025-01-08T19:14:15.896Z [du] 
    2025-01-08T19:14:15.896Z [du] [NR_MAC]   Frame.Slot 512.0
    2025-01-08T19:14:17.176Z [du] 
    2025-01-08T19:14:17.176Z [du] [NR_MAC]   Frame.Slot 640.0
    2025-01-08T19:14:18.456Z [du] 
    2025-01-08T19:14:18.456Z [du] [NR_MAC]   Frame.Slot 768.0
    2025-01-08T19:14:19.736Z [du] 
    2025-01-08T19:14:19.736Z [du] [NR_MAC]   Frame.Slot 896.0
    2025-01-08T19:14:21.016Z [du] 
    2025-01-08T19:14:21.016Z [du] [NR_MAC]   Frame.Slot 0.0
    2025-01-08T19:14:22.297Z [du] 
    2025-01-08T19:14:22.297Z [du] [NR_MAC]   Frame.Slot 128.0
    2025-01-08T19:14:23.576Z [du] 
    2025-01-08T19:14:23.576Z [du] [NR_MAC]   Frame.Slot 256.0
    2025-01-08T19:14:24.856Z [du] 
    ```

    Here, notice the line `[RAU] has loaded USRP B200 device.` which indicates that the USRP radio is detected.

    The USRP radio LED should turn on. The Rx light should be a solid green and the Tx light should be a solid red.


[DU Configuration]: https://charmhub.io/oai-ran-du-k8s/configurations?channel=2.2/edge
