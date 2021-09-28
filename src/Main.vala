/*
 * Copyright (c) 2021 Payson Wallach
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

public static LogWriterOutput log_writer_func (LogLevelFlags log_level, LogField[] fields) {
    if (log_level >= LogLevelFlags.LEVEL_WARNING || Environment.get_variable ("G_MESSAGES_DEBUG") == "all") {
        GLib.Log.writer_journald (log_level, fields);
        return LogWriterOutput.HANDLED;
    }

    return LogWriterOutput.UNHANDLED;
}

public static int main (string[] argv) {
    TrackerWeb.Application app;

    GLib.Log.set_writer_func (log_writer_func);

    try {
        app = new TrackerWeb.Application ();
    } catch (Error e) {
        error (e.message);
    }

    Unix.signal_add (Posix.Signal.TERM, () => {
        app.terminate ();
        return Source.REMOVE;
    });

    return app.run ();
}
