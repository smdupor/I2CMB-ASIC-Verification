class i2c_rand_data_transaction extends i2c_transaction;

  `ncsu_register_object(i2c_rand_data_transaction)

  randc bit [7:0] tmp_addr;
  rand int tmp_op;
  randc int tmp_bus;
  rand bit [7:0] tmp_data[$];
  int size;

  int clock_stretch_qty;


  // Coverage Only
  logic is_restart;  // x for N/a, 0 For "START", 1 for "RE-START"
  int explicit_wait_ms;  // This was preceeded by an explicit "Wait" Command

  // ****************************************************************************
  // Constraints and Randomization
  // ****************************************************************************
  constraint bus_sel_range {    // Legal bus values
    tmp_bus dist {
      [0 : 15]
    };
  }
  constraint adr_range {     // Legal address range
    tmp_addr dist {
      [0 : 127]
    };
  }
  constraint op_wt {          // Weight towards read/write operations
    tmp_op dist {
      [ 0 :  50] :/ 5,
      [51 : 100] :/ 5
    };
  }

  // Randomize the number of bytes of data in this transaction, whether it be single or burst
  function void pre_randomize();
    size = $urandom_range(1, 2);
    for (int i = 0; i < size; ++i) tmp_data.push_back(byte'(8'hff));
    data = tmp_data;
  endfunction

// Handle the randomized data including operation selection
  function void post_randomize();
    foreach (tmp_data[i]) data[i] = tmp_data[i];
    address = tmp_addr;
    selected_bus = tmp_bus;
    if (tmp_op > 50) rw = I2_WRITE;
    else rw = I2_READ;

  endfunction


  // ****************************************************************************
  // Construction, setters and getters
  // ****************************************************************************
  function new(string name = "");
    super.new(name);

  endfunction

  function void set(bit [7:0] address, bit [7:0] data[], i2c_op_t rw, int selected_bus);
    this.address = address;
    this.data = data;
    this.rw = rw;
    this.selected_bus = selected_bus;
  endfunction

  // ****************************************************************************
  // to_string LEGACY implementation, without calls to superclass
  // ****************************************************************************
  function string convert2string_legacy();
    string s, temp;
    temp.itoa(integer'(selected_bus));
    if (rw == I2_WRITE) begin
      s = {"I2C_BUS ", temp, " WRITE Transfer To  randdat Address: "};
    end else begin
      s = {"I2C_BUS ", temp, " READ  Transfer From randdat Address: "};
    end

    // Add ADDRESS associated with transfer to string, followed by "Data: " tag
    temp.itoa(integer'(address));
    s = {s, temp, " Data: "};

    // Concatenate each data byte to string. PRINT_LINE_LEN parameter introduces a
    // number-of-characters cap, beyond which each  line will be wrapped to the nextline.
    foreach (data[i]) begin

      temp.itoa(integer'(data[i]));
      s = {s, temp, ","};
    end
    return s.substr(0, s.len - 2);

  endfunction

  // ****************************************************************************
  // Complete to_string functionality
  // ****************************************************************************
  virtual function string convert2string();
    return {super.convert2string(), convert2string_legacy()};
  endfunction

  // ****************************************************************************
  // Check match between two I2C Transactions
  // ****************************************************************************
  function bit compare(i2c_transaction other);
    if (this.address != other.address) return 0;
    if (this.rw != other.rw) return 0;
    foreach (this.data[i]) begin
      if (this.data[i] != other.data[i]) return 0;
    end
    return 1;
  endfunction

endclass
