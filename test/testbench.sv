// Transaction class for SPI data
class transaction;  
    bit newd;                
    rand bit [11:0] din;      
    bit [11:0] dout;          
  
    function transaction copy();
        copy = new();             
        copy.newd = this.newd;   
        copy.din  = this.din;     
        copy.dout = this.dout;    
    endfunction
endclass

// Generator class to create random transactions
class generator;
    transaction tr;          
    mailbox #(transaction) mbx; 
    event done;             
    int count = 0;          
    event drvnext;           // Event for driver sync
    event sconext;           // Event for scoreboard sync
  
    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;          
        tr = new();              
    endfunction
  
    task run();
        repeat(count) begin
            assert(tr.randomize) else $error("[GEN] :Randomization Failed");
            mbx.put(tr.copy);    // Put transaction in mailbox
            $display("[GEN] : din : %0d", tr.din);
            @(sconext);          // Wait for scoreboard sync
        end
        -> done;                
    endtask
endclass

// Driver class to drive transactions to DUT
class driver;
    virtual spi_if vif;      
    transaction tr;          
    mailbox #(transaction) mbx; 
    mailbox #(bit [11:0]) mbxds; 
    event drvnext;          // Event for generator sync
    bit [11:0] din;        
  
    function new(mailbox #(bit [11:0]) mbxds, mailbox #(transaction) mbx);
        this.mbx = mbx;          
        this.mbxds = mbxds;
    endfunction
  
    // Reset task
    task reset();
        vif.rst <= 1'b1;         
        vif.newd <= 1'b0;        
        vif.din <= 1'b0;         
        repeat(10) @(posedge vif.clk);
        vif.rst <= 1'b0;         
        repeat(5) @(posedge vif.clk);
        $display("[DRV] : RESET DONE");
        $display("-----------------------------------------");
    endtask
  
    task run();
        forever begin
            mbx.get(tr);         
            vif.newd <= 1'b1;    
            vif.din <= tr.din;   
            mbxds.put(tr.din);   
            @(posedge vif.sclk);
            vif.newd <= 1'b0;    
            @(posedge vif.done);
            $display("[DRV] : DATA SENT TO DAC : %0d",tr.din);
            @(posedge vif.sclk);
        end
    endtask
endclass

// Monitor class to capture DUT outputs
class monitor;
    transaction tr;          
    mailbox #(bit [11:0]) mbx; 
    virtual spi_if vif;     
  
    function new(mailbox #(bit [11:0]) mbx);
        this.mbx = mbx;     
    endfunction
  
    task run();
        tr = new();         
        forever begin
            @(posedge vif.sclk);
            @(posedge vif.done);
            tr.dout = vif.dout;
            @(posedge vif.sclk);
            $display("[MON] : DATA SENT : %0d", tr.dout);
            mbx.put(tr.dout);       // Send to scoreboard
        end  
    endtask
endclass

// Scoreboard class to verify data
class scoreboard;
    mailbox #(bit [11:0]) mbxds, mbxms; 
    bit [11:0] ds, ms;                  // Data from driver and monitor
    event sconext;                       
  
    function new(mailbox #(bit [11:0]) mbxds, mailbox #(bit [11:0]) mbxms);
        this.mbxds = mbxds;            
        this.mbxms = mbxms;
    endfunction
  
    task run();
        forever begin
            mbxds.get(ds);              // Get driver data
            mbxms.get(ms);              // Get monitor data
            $display("[SCO] : DRV : %0d MON : %0d", ds, ms);
            
            if(ds == ms)
                $display("[SCO] : DATA MATCHED");
            else
                $display("[SCO] : DATA MISMATCHED");
            
            $display("-----------------------------------------");
            ->sconext;                  
        end
    endtask
endclass

// Environment class to coordinate verification
class environment;
    generator gen;                
    driver drv;                    
    monitor mon;                   
    scoreboard sco;                
    event nextgd, nextgs;          
    mailbox #(transaction) mbxgd; 
    mailbox #(bit [11:0]) mbxds, mbxms; 
    virtual spi_if vif;           
  
    function new(virtual spi_if vif);
        mbxgd = new();            
        mbxms = new();
        mbxds = new();
        gen = new(mbxgd);          
        drv = new(mbxds,mbxgd);
        mon = new(mbxms);
        sco = new(mbxds, mbxms);
        this.vif = vif;           
        drv.vif = this.vif;
        mon.vif = this.vif;
        gen.sconext = nextgs;      
        sco.sconext = nextgs;
        gen.drvnext = nextgd;
        drv.drvnext = nextgd;
    endfunction
  
    task pre_test();
        drv.reset();               
    endtask
  
    task test();
        fork                        // Run components in parallel
            gen.run();             
            drv.run();             
            mon.run();              
            sco.run();              
        join_any
    endtask
  
    task post_test();
        wait(gen.done.triggered);   
        $finish();
    endtask
  
    task run();
        pre_test();
        test();
        post_test();
    endtask
endclass

// Testbench module
module tb;
    spi_if vif();                
    top dut(vif.clk,vif.rst,vif.newd,vif.din,vif.dout,vif.done);
  
    initial begin
        vif.clk <= 0;
    end
      
    always #10 vif.clk <= ~vif.clk;
  
    environment env;              
  
    assign vif.sclk = dut.m1.sclk;
  
    // Main simulation
    initial begin
        env = new(vif);           
        env.gen.count = 4;       
        env.run();                
    end
      
    // Waveform dumping
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
endmodule 