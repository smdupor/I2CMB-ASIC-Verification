class i2cmb_predictor_regblock extends i2cmb_predictor;

  typedef enum int {
    DEFAULT_TESTING,
    ACCESS_CONTROL,
    CROSSCHECKING,
    ERROR_TESTING
  } pred_reg_states;

  wb_transaction last_trans[$];  // Keep a historic buffer of recent xations
  const bit [7:0] default_values[4] = {8'h0, 8'h0, 8'b1000_0000, 8'h0};
  bit [7:0] reg_file[4];
  pred_reg_states state;
  int transaction_count;
  wb_transaction itrans;

  // ****************************************************************************
  // Construction, setters, and getters 
  // ****************************************************************************
  function new(string name = "", ncsu_component_base parent = null);
    super.new(name, parent);
    state = DEFAULT_TESTING;
  endfunction

  // ****************************************************************************
  // Called from wb_agent, process all incoming monitored wb transactions.
  // ****************************************************************************
  virtual function void nb_put(ncsu_transaction trans);
    if (configuration.enable_error_testing) state = ERROR_TESTING;

    $cast(itrans, trans);  // Grab incoming transaction process

    // Copy incoming transaction data into persistent data structure
    adr_mon  = itrans.line;
    dat_mon  = itrans.word;
    we_mon   = itrans.write;
    is_write = itrans.write;

    ncsu_info("", {"        ", get_full_name(), itrans.to_s_uglyprint_dat()},
              NCSU_LOW);  // Print only pertinent WB transactions per project spec.

    //Based on REGISTER Address of received transaction, process transaction data accordingly
    case (state)
      DEFAULT_TESTING: process_default_testing();
      ACCESS_CONTROL:  process_access_ctrl_testing();
      CROSSCHECKING:   process_crosschecking();
      ERROR_TESTING:   process_error_testing();
    endcase
    ++transaction_count;
    last_trans.push_back(itrans);
  endfunction

  function void process_default_testing();
    case (adr_mon)

      CSR:
      assert_csr_enable_defaults :
      assert (dat_mon == default_values[adr_mon])
      else $error("Assertion CSR defaults FAILED! GOT: %b", dat_mon);


      DPR:
      assert_dpr_default_on_enable :
      assert (dat_mon == default_values[adr_mon])
      else $error("Assertion assert_dpr_default value failed! GOT: %b", dat_mon);


      CMDR:
      assert_cmdr_default_on_enable :
      assert (dat_mon == default_values[adr_mon])
      else $error("Assertion assert_cmdr_default value failed! GOT: %b", dat_mon);

      FSMR: begin
        assert_fsmr_default_on_enable :
        assert (dat_mon == default_values[adr_mon])
        else $error("Assertion assert_fsmr_default_on_enable failed! GOT: %b", dat_mon);
        state = ACCESS_CONTROL;
      end
    endcase

  endfunction

  function void process_access_ctrl_testing();
    if (!we_mon) begin

      case (adr_mon)

        CSR: begin
          assert_csr_ro :
          assert (dat_mon == default_values[adr_mon])
          else $error("Assertion assert_csr_ro FAILED! GOT: %b", dat_mon);
          reg_file[adr_mon] = default_values[adr_mon];
        end
        DPR: begin
          assert_dpr_ro :
          assert (dat_mon == default_values[adr_mon])
          else $error("Assertion assert_dpr_ro failed! GOT: %b", dat_mon);
          reg_file[adr_mon] = default_values[adr_mon];
        end
        CMDR: begin
          assert_cmdr_ro :
          assert (dat_mon == default_values[adr_mon])
          else $error("Assertion assert_cmdr_ro failed! GOT: %b", dat_mon);
          reg_file[adr_mon] = default_values[adr_mon];
        end
        FSMR: begin
          assert_fsmr_ro :
          assert (dat_mon == default_values[adr_mon])
          else $error("Assertion assert_fsmr_ro failed! GOT: %b", dat_mon);
          state = CROSSCHECKING;
          reg_file[adr_mon] = default_values[adr_mon];
        end
      endcase
    end
  endfunction

  function void process_crosschecking();

    // Accept the written value into predictor's copy of the register fiile
    if (we_mon) begin
      if (adr_mon != DPR)
        reg_file[adr_mon] = dat_mon;		// DPR Values are flushed on a completed write to the lower-level FSM
      if (adr_mon == CMDR)
        reg_file[CMDR] = 8'b0001_0111;	// A write to CMDR with an illegal DPR value will cause the CMDR Error bit to rise
    end else begin
      // On the following reads, ensure the predicted register file still matches the DUT registers.
      case (adr_mon)
        CSR:
        assert_csr_cross :
        assert (dat_mon == reg_file[adr_mon])
        else
          $error(
              "Assertion assert_csr_cross FAILED! GOT: %b Expect: %b", dat_mon, reg_file[adr_mon]
          );

        DPR:
        assert_dpr_cross :
        assert (dat_mon == reg_file[adr_mon])
        else
          $error(
              "Assertion assert_dpr_cross failed! GOT: %b Expect: %b", dat_mon, reg_file[adr_mon]
          );

        CMDR:
        assert_cmdr_cross :
        assert (dat_mon == reg_file[adr_mon])
        else
          $error(
              "Assertion assert_cmdr_cross failed! GOT: %b Expect: %b", dat_mon, reg_file[adr_mon]
          );

        FSMR: begin
          assert_fsmr_cross :
          assert (dat_mon == reg_file[adr_mon])
          else
            $error(
                "Assertion assert_fsmr_cross failed! GOT: %b EXPECTED: %b",
                dat_mon,
                reg_file[adr_mon]
            );
        end
      endcase
    end

  endfunction

  function void process_error_testing();
    // Accept the written value into predictor's copy of the register fiile
    if (!we_mon && adr_mon == CMDR) begin
      assert_cmdr_done_or_error :
      assert ((dat_mon[7] == 1'b1 || dat_mon[4] == 1'b1))
      else $error("Assertion assert_cmdr_done_or_error failed! GOT: %b", dat_mon);
    end
  endfunction


endclass
