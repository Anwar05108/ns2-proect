#===================================
#     Simulation parameters setup
#===================================
expr srand(80)

set val(stop)   20.0                         ;# time of simulation end
set val(rate) 50kb
set val(no_of_nodes) [lindex $argv 0]
set val(nf) [lindex $argv 1] 
set val(pktpersec) [lindex $argv 2]

set val(pkt_size) 1000
set val(report_interval) 1000ms
# [expr int($val(nn) * rand()) % $val(nn)]
set sender_no [expr int(rand() * $val(no_of_nodes))]
set receiver_no [expr int(rand() * $val(no_of_nodes))]
while {$sender_no == $receiver_no} {
    set receiver_no [expr {int(rand()*$val(no_of_nodes))}]
}

set receiver_no2 [expr int(rand() * $val(no_of_nodes))]
while {$receiver_no2 == $receiver_no || $receiver_no2 == $sender_no} {
    set receiver_no2 [expr int(rand() * $val(no_of_nodes))]
}





#===================================
#        Initialization        
#===================================
#Create a ns simulator
set ns [new Simulator -multicast on]
#Define different colors for data flows
$ns color 1 red
$ns color 30 purple
$ns color 31 bisque
$ns color 32 green


#Open the NS trace file
set tracefile [open trace.tr w]
$ns trace-all $tracefile

#Open the NAM trace file
set namfile [open out.nam w]
$ns namtrace-all $namfile

#Open trace files
# set f0 [open tcp0.tr w]
# set f1 [open tcp1.tr w]
# set f2 [open tcp2.tr w]
# set f3 [open tcp3.tr w]
# set r0 [open rtp-tx.tr w]



#===================================
#        Nodes Definition        
#===================================
#Create n nodes
# set n 20
for {set i 0} {$i < $val(no_of_nodes)} {incr i} {
    set node($i) [$ns node]
    $node($i) shape "box"
    if {$i == $sender_no} {$node($i) label "RTP-Sender"}
    if {$i == $receiver_no || $i == $receiver_no2} {$node($i) label "RTP-Receiver"}
}

#===================================
#        Links Definition        
#===================================
#Create links between nodes
for {set i 0} {$i < $val(no_of_nodes)} {incr i} {
    set j [expr {($i+1) % $val(no_of_nodes)}]
    $ns duplex-link $node($i) $node($j) 10.0Mb 10ms DropTail
    $ns queue-limit $node($i) $node($j) 50
}

#===================================
#        Agents Definition        
#===================================
# Setup a TCP connection
# Setup a TCP connection
# for {set i 0} {$i < $val(nf)} {incr i} {
#     set tcp($i) [new Agent/TCP]

    

#     $ns attach-agent $node([expr {($i) % $val(no_of_nodes)}]) $tcp($i)
#     # set j [expr {($i+1) % $val(no_of_nodes)}]
#     set sink($i) [new Agent/TCPSink]
#     set gap [expr {int(rand()*$val(no_of_nodes))}]
#     $ns attach-agent $node([expr {($i+$gap) % $val(no_of_nodes)}]) $sink($j)
#     $ns connect $tcp($i) $sink($i)
#     $tcp($i) set packetSize_ 1000
#     $tcp($i) set window_ [expr 10 *($val(pktpersec) / 100)]

#     set ftp($i) [new Application/FTP]
#     $ftp($i) attach-agent $tcp($i)
   
# }

# for {set i 0} {$i < $val(nf)} {incr i} {
#      $ns at 1.0 "$ftp($i) start"
#     $ns at 20.0 "$ftp($i) stop"
# }


set sink [expr int( rand() * 1000 ) % $val(no_of_nodes) ]



 puts "Sink is $sink"

for {set i 0} {$i < $val(nf)} {incr i} {
     while {1 == 1} {
        set src [expr int($val(no_of_nodes) * rand()) % $val(no_of_nodes)]
        # puts "set in while loop src $src"
        if {$src != $sink} {
            break
        }
    }

    # set src $i
    # puts "set in for loop  src $i"
    # set sink [expr 19 - $i]

    # Traffic config
    # create agent
    set tcp [new Agent/TCP]
    set tcp_sink [new Agent/TCPSink]
    # attach to nodes
    $ns attach-agent $node($src) $tcp
    $ns attach-agent $node($sink) $tcp_sink
    # connect agents
    $ns connect $tcp $tcp_sink
    $tcp set fid_ $i

    # Traffic generator
    set ftp [new Application/FTP]
    # attach to agent
    $ftp attach-agent $tcp
    
    # start traffic generation
    $ns at 1.0 "$ftp start"
}









#===================================
#        RTP-TCP Friendly Multicast
#===================================
# configure multicast protocol;
#set mproto CtrMcast
set mproto DM
# all nodes will contain multicast protocol agents;
set mrthandle [$ns mrtproto $mproto]         
# allocate a multicast address;
set group [Node allocaddr]

# Node 2, the multicast sender
set s0 [new Session/RTP ]
$s0 report-interval $val(report_interval)
$s0 session_bw $val(rate)
# $s0 initial-rate  $val(rate)
$s0 attach-node $node($sender_no)   
# enable TCP-Friendly congestion control
#by default is 0
# $s0 enable-control 1

#Node 3, receiver
set s1 [new Session/RTP ]
$s1 report-interval $val(report_interval)
# $s1 initial-rate  $val(rate)
$s1 session_bw  $val(rate)
$s1 attach-node $node($receiver_no)

#Node 4, receiver
set s2 [new Session/RTP ]
$s2 report-interval $val(report_interval)
# $s2 initial-rate  $val(rate)
$s2 session_bw $val(rate)
$s2 attach-node $node($receiver_no2)

#joining the group
$ns at 0.1 "$s0 join-group $group"
$ns at 0.1 "$s0 start"

$ns at 0.1 "$s1 join-group $group"
$ns at 0.1 "$s1 start"

$ns at 0.1 "$s2 join-group $group"
$ns at 0.1 "$s2 start"

#RTP sender starts transmission
$ns at 1.0 "$s0 transmit $val(rate)"


# $ns at $val(tend) "finish"

# Define 'finish' procedure (include post-simulation processes)
proc finish {} {
    # global ns tracefile namfile
    # $ns flush-trace
    # close $tracefile
    # close $namfile
    # close $f0
    # close $f1
    # close $f2
    # close $f3
    # close $r0
    # exec nam animation.nam &
    #Call xgraph to display the results
    # exec xgraph rtp-tx.tr tcp0.tr tcp1.tr tcp2.tr tcp3.tr     -geometry 800x400  &
    exit 0
}


$ns at $val(stop) "finish"
$ns at $val(stop) "puts \"done\" ; $ns halt"
# $ns run
$ns run
