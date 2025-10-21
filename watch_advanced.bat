@if (@X)==(@Y) @end /*

@echo off
setlocal

cscript //nologo //E:JScript "%~f0" %*
exit /b %errorlevel%

*/

var VERSION = "1.0.0";
var shell = new ActiveXObject("WScript.Shell");
var env = shell.Environment("Process");
var args = WScript.Arguments;
var optionStop = false;
var options = {
    intervalMs: 2000,
    intervalDisplay: "2.0",
    differences: false,
    cumulative: false,
    title: true,
    help: false,
    version: false
};
var commandParts = [];
var i = 0;

function parseInterval(value) {
    if (value === null || value === undefined || value === "") {
        throw new Error("interval must be greater than zero");
    }
    value = value.replace(/,/g, ".");
    if (!/^\d*(?:\.\d*)?$/.test(value)) {
        throw new Error("invalid interval '" + value + "'");
    }
    if (value === "") {
        throw new Error("invalid interval '" + value + "'");
    }
    if (value.charAt(0) === ".") {
        value = "0" + value;
    }
    var parsed = parseFloat(value);
    if (!isFinite(parsed) || parsed <= 0) {
        throw new Error("interval must be greater than zero");
    }
    var millis = Math.round(parsed * 1000);
    if (millis <= 0) {
        throw new Error("interval must be greater than zero");
    }
    options.intervalMs = millis;
    var display = parsed.toFixed(2);
    if (display.substring(display.length - 1) === "0") {
        display = parsed.toFixed(1);
    }
    options.intervalDisplay = display;
}

function applyDifferences(mode) {
    if (!mode) {
        options.differences = true;
        options.cumulative = false;
        return;
    }
    if (mode.toLowerCase() === "cumulative") {
        options.differences = true;
        options.cumulative = true;
        return;
    }
    throw new Error("invalid differences mode '" + mode + "'");
}

while (i < args.length) {
    var arg = args.Item(i);
    if (optionStop) {
        commandParts.push(arg);
        i++;
        continue;
    }
    if (arg === "--") {
        optionStop = true;
        i++;
        continue;
    }
    if (arg === "-h" || arg === "--help") {
        options.help = true;
        i++;
        continue;
    }
    if (arg === "-v" || arg === "--version") {
        options.version = true;
        i++;
        continue;
    }
    if (arg === "-t" || arg === "--no-title") {
        options.title = false;
        i++;
        continue;
    }
    if (arg === "-d" || arg === "--differences") {
        options.differences = true;
        options.cumulative = false;
        i++;
        continue;
    }
    if (arg.indexOf("-d=") === 0) {
        applyDifferences(arg.substring(3));
        i++;
        continue;
    }
    if (arg.indexOf("--differences=") === 0) {
        applyDifferences(arg.substring(14));
        i++;
        continue;
    }
    if (arg === "-n" || arg === "--interval") {
        i++;
        if (i >= args.length) {
            WScript.StdErr.WriteLine("watch: option requires an argument -- n");
            WScript.Quit(2);
        }
        try {
            parseInterval(args.Item(i));
        } catch (err) {
            WScript.StdErr.WriteLine("watch: " + err.message);
            WScript.Quit(2);
        }
        i++;
        continue;
    }
    if (arg.indexOf("-n") === 0 && arg.length > 2) {
        try {
            parseInterval(arg.substring(2));
        } catch (err) {
            WScript.StdErr.WriteLine("watch: " + err.message);
            WScript.Quit(2);
        }
        i++;
        continue;
    }
    if (arg.indexOf("--interval=") === 0) {
        try {
            parseInterval(arg.substring(11));
        } catch (err) {
            WScript.StdErr.WriteLine("watch: " + err.message);
            WScript.Quit(2);
        }
        i++;
        continue;
    }
    if (arg.charAt(0) === "-") {
        WScript.StdErr.WriteLine("watch: unrecognized option " + arg);
        WScript.Quit(2);
    }
    break;
}

for (; i < args.length; i++) {
    commandParts.push(args.Item(i));
}

if (options.help) {
    WScript.StdOut.WriteLine("Usage: watch [options] command");
    WScript.StdOut.WriteLine("");
    WScript.StdOut.WriteLine("Options:");
    WScript.StdOut.WriteLine("  -n, --interval <seconds>   Specify the update interval (default: 2)");
    WScript.StdOut.WriteLine("  -d, --differences           Highlight differences between updates");
    WScript.StdOut.WriteLine("  -d=cumulative               Keep differences highlighted across updates");
    WScript.StdOut.WriteLine("      --differences[=MODE]   Same as -d with optional MODE=cumulative");
    WScript.StdOut.WriteLine("  -t, --no-title              Disable the header at the top of the display");
    WScript.StdOut.WriteLine("  -h, --help                  Show this help message and exit");
    WScript.StdOut.WriteLine("  -v, --version               Show version information and exit");
    WScript.Quit(0);
}

if (options.version) {
    WScript.StdOut.WriteLine("watch.bat version " + VERSION);
    WScript.Quit(0);
}

if (commandParts.length === 0) {
    WScript.StdErr.WriteLine("Usage: watch [options] command");
    WScript.StdErr.WriteLine("Try 'watch --help' for more information.");
    WScript.Quit(2);
}

function quoteArgumentForCmd(arg) {
    if (arg.length === 0) {
        return '""';
    }
    var needQuotes = /\s|"/.test(arg);
    if (!needQuotes) {
        return arg;
    }
    var result = '"';
    var backslashes = 0;
    for (var j = 0; j < arg.length; j++) {
        var ch = arg.charAt(j);
        if (ch === '\\') {
            backslashes++;
        } else if (ch === '"') {
            result += new Array(backslashes * 2 + 1).join('\\');
            result += '\\"';
            backslashes = 0;
        } else {
            if (backslashes > 0) {
                result += new Array(backslashes + 1).join('\\');
                backslashes = 0;
            }
            result += ch;
        }
    }
    if (backslashes > 0) {
        result += new Array(backslashes * 2 + 1).join('\\');
    }
    result += '"';
    return result;
}

var commandDisplay = commandParts.join(" ");
var commandLineParts = [];
for (var c = 0; c < commandParts.length; c++) {
    commandLineParts.push(quoteArgumentForCmd(commandParts[c]));
}
var commandLine = commandLineParts.join(" ");

function escapeForCmdInvocation(text) {
    return text.replace(/"/g, '""');
}

var mergedCommand = 'cmd.exe /s /c "' + escapeForCmdInvocation(commandLine) + ' 2>&1"';

function clearScreen() {
    WScript.StdOut.Write("\u001b[2J\u001b[H");
}

function formatDateTime(dt) {
    var datePart = dt.toDateString ? dt.toDateString() : dt.toString();
    var timePart = dt.toLocaleTimeString ? dt.toLocaleTimeString() : '';
    return datePart + (timePart ? ' ' + timePart : '');
}

function splitLines(text) {
    if (text.length === 0) {
        return [];
    }
    var trimmed = text;
    if (trimmed.slice(-2) === '\r\n') {
        trimmed = trimmed.slice(0, -2);
    } else if (trimmed.slice(-1) === '\n') {
        trimmed = trimmed.slice(0, -1);
    }
    if (trimmed.length === 0) {
        return [""];
    }
    return trimmed.split(/\r?\n/);
}

var previousLines = [];
var cumulativeFlags = [];
var hasPrevious = false;
var useColor = true;
var noColorEnv = env("WATCH_NO_COLOR");
if (noColorEnv && noColorEnv.length > 0) {
    useColor = false;
}

function printLine(text) {
    WScript.StdOut.WriteLine(text);
}

function printHighlighted(text) {
    if (useColor) {
        WScript.StdOut.WriteLine("\u001b[93m" + text + "\u001b[0m");
    } else {
        WScript.StdOut.WriteLine("* " + text);
    }
}

while (true) {
    var exec = shell.Exec(mergedCommand);
    while (exec.Status === 0) {
        WScript.Sleep(50);
    }
    var output = exec.StdOut.ReadAll();
    var exitCode = exec.ExitCode;
    var lines = splitLines(output);

    clearScreen();
    if (options.title) {
        printLine("Every " + options.intervalDisplay + "s: " + commandDisplay);
        printLine(formatDateTime(new Date()));
        printLine("");
    }

    if (lines.length === 0) {
        // Nothing to print
    } else {
        for (var idx = 0; idx < lines.length; idx++) {
            var current = lines[idx];
            var highlight = false;
            if (options.differences && hasPrevious) {
                var previous = previousLines[idx];
                if (typeof previous === "undefined") {
                    highlight = true;
                    if (options.cumulative) {
                        cumulativeFlags[idx] = true;
                    }
                } else if (previous !== current) {
                    highlight = true;
                    if (options.cumulative) {
                        cumulativeFlags[idx] = true;
                    }
                } else if (options.cumulative && cumulativeFlags[idx]) {
                    highlight = true;
                }
            } else if (options.differences && options.cumulative && cumulativeFlags[idx]) {
                highlight = true;
            }
            if (highlight) {
                printHighlighted(current);
            } else {
                printLine(current);
            }
            previousLines[idx] = current;
            if (!options.cumulative) {
                cumulativeFlags[idx] = false;
            }
        }
    }

    if (previousLines.length > lines.length) {
        previousLines.length = lines.length;
    }
    if (!options.cumulative) {
        cumulativeFlags.length = lines.length;
    } else if (cumulativeFlags.length > lines.length) {
        cumulativeFlags.length = lines.length;
    }

    printLine("");
    printLine("Exit code: " + exitCode);

    hasPrevious = true;
    WScript.Sleep(options.intervalMs);
}
