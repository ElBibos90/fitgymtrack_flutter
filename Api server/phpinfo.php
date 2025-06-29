<?php
echo "Current PHP user: " . exec('whoami');
echo "<br>Process owner: " . get_current_user();
?>