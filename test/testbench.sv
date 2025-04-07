// Transaction class for SPI data
class transaction;  
    bit newd;                 // Control signal for new data
    rand bit [11:0] din;      // Random 12-bit data input
    bit [11:0] dout;          // 12-bit output data
  
    // Create a copy of the transaction
    function transaction copy();
        copy = new();             
        copy.newd = this.newd;   
        copy.din  = this.din;     
        copy.dout = this.dout;    
    endfunction
endclass

// Generator class to create random transactions
class generator;
    transaction tr;           // Transaction object
    mailbox #(transaction) mbx; // Mailbox for transactions
    event done;               // Done event
    int count = 0;           // Transaction count
    event drvnext;           // Event for driver sync
    event sconext;           // Event for scoreboard sync
  
    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;          // Initialize mailbox
        tr = new();              // Create transaction object
    endfunction
  
    task run();
        repeat(count) begin
            assert(tr.randomize) else $error("[GEN] :Randomization Failed");
            mbx.put(tr.copy);    // Put transaction in mailbox
            $display("[GEN] : din : %0d", tr.din);
            @(sconext);          // Wait for scoreboard sync
        end
        -> done;                 // Signal completion
    endtask
endclass

// Driver class to drive transactions to DUT
class driver;
    virtual spi_if vif;      // Virtual interface
    transaction tr;          // Transaction object
    mailbox #(transaction) mbx; // Mailbox for transactions
    mailbox #(bit [11:0]) mbxds; // Mailbox for data output
    event drvnext;          // Event for generator sync
    bit [11:0] din;        // Data input
  
    function new(mailbox #(bit [11:0]) mbxds, mailbox #(transaction) mbx);
        this.mbx = mbx;          // Initialize mailboxes
        this.mbxds = mbxds;
    endfunction
  
    // Reset task
    task reset();
        vif.rst <= 1'b1;         // Assert reset
        vif.newd <= 1'b0;        // Clear new data
        vif.din <= 1'b0;         // Clear data input
        repeat(10) @(posedge vif.clk);
        vif.rst <= 1'b0;         // Deassert reset
        repeat(5) @(posedge vif.clk);
        $display("[DRV] : RESET DONE");
        $display("-----------------------------------------");
    endtask
  
    task run();
        forever begin
            mbx.get(tr);         // Get transaction
            vif.newd <= 1'b1;    // Assert new data
            vif.din <= tr.din;   // Drive data
            mbxds.put(tr.din);   // Send to monitor
            @(posedge vif.sclk);
            vif.newd <= 1'b0;    // Clear new data
            @(posedge vif.done);
            $display("[DRV] : DATA SENT TO DAC : %0d",tr.din);
            @(posedge vif.sclk);
        end
    endtask
endclass

// Monitor class to capture DUT outputs
class monitor;
    transaction tr;          // Transaction object
    mailbox #(bit [11:0]) mbx; // Mailbox for data
    virtual spi_if vif;      // Virtual interface
  
    function new(mailbox #(bit [11:0]) mbx);
        this.mbx = mbx;      // Initialize mailbox
    endfunction
  
    task run();
        tr = new();          // Create transaction
        forever begin
            @(posedge vif.sclk);
            @(posedge vif.done);
            tr.dout = vif.dout;     // Capture output
            @(posedge vif.sclk);
            $display("[MON] : DATA SENT : %0d", tr.dout);
            mbx.put(tr.dout);       // Send to scoreboard
        end  
    endtask
endclass

// Scoreboard class to verify data
class scoreboard;
    mailbox #(bit [11:0]) mbxds, mbxms; // Mailboxes for data
    bit [11:0] ds, ms;                  // Data from driver and monitor
    event sconext;                       // Event for sync
  
    function new(mailbox #(bit [11:0]) mbxds, mailbox #(bit [11:0]) mbxms);
        this.mbxds = mbxds;             // Initialize mailboxes
        this.mbxms = mbxms;
    endfunction
  
    task run();
        forever begin
            mbxds.get(ds);              // Get driver data
            mbxms.get(ms);              // Get monitor data
            $display("[SCO] : DRV : %0d MON : %0d", ds, ms);
            
            if(ds == ms)                // Compare data
                $display("[SCO] : DATA MATCHED");
            else
                $display("[SCO] : DATA MISMATCHED");
            
            $display("-----------------------------------------");
            ->sconext;                  // Signal completion
        end
    endtask
endclass

// Environment class to coordinate verification
class environment;
    generator gen;                 // Generator instance
    driver drv;                    // Driver instance
    monitor mon;                   // Monitor instance
    scoreboard sco;                // Scoreboard instance
    event nextgd, nextgs;          // Sync events
    mailbox #(transaction) mbxgd;  // Mailbox for transactions
    mailbox #(bit [11:0]) mbxds, mbxms; // Mailboxes for data
    virtual spi_if vif;            // Virtual interface
  
    function new(virtual spi_if vif);
        mbxgd = new();             // Create mailboxes
        mbxms = new();
        mbxds = new();
        gen = new(mbxgd);          // Create components
        drv = new(mbxds,mbxgd);
        mon = new(mbxms);
        sco = new(mbxds, mbxms);
        this.vif = vif;            // Connect interface
        drv.vif = this.vif;
        mon.vif = this.vif;
        gen.sconext = nextgs;      // Connect events
        sco.sconext = nextgs;
        gen.drvnext = nextgd;
        drv.drvnext = nextgd;
    endfunction
  
    task pre_test();
        drv.reset();               // Perform reset
    endtask
  
    task test();
        fork                        // Run components in parallel
            gen.run();              // Run generator
            drv.run();              // Run driver
            mon.run();              // Run monitor
            sco.run();              // Run scoreboard
        join_any
    endtask
  
    task post_test();
        wait(gen.done.triggered);   // Wait for completion
        $finish();
    endtask
  
    task run();
        pre_test();                 // Run test phases
        test();
        post_test();
    endtask
endclass

// Testbench module
module tb;
    spi_if vif();                 // Create interface
    top dut(vif.clk,vif.rst,vif.newd,vif.din,vif.dout,vif.done); // Instantiate DUT
  
    // Clock generation
    initial begin
        vif.clk <= 0;
    end
      
    always #10 vif.clk <= ~vif.clk;
  
    environment env;               // Environment instance
  
    assign vif.sclk = dut.m1.sclk; // Connect SPI clock
  
    // Main simulation
    initial begin
        env = new(vif);           // Create environment
        env.gen.count = 4;        // Set transaction count
        env.run();                // Run test
    end
      
    // Waveform dumping
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
endmodule 