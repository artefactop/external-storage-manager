/*

    External Storage Manager, manage external peripherals
    Copyright 2012, Jose Luis Navarro


    This file is part of External Storage Manager.

    Ejecter is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ejecter is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with External Storate Manager.  If not, see <http://www.gnu.org/licenses/>.

*/

using GLib;

namespace ExternalStorageManager {

    public class DeviceMenuItem: Gtk.ImageMenuItem {

        private ExternalStorageManager.Device device;

        public DeviceMenuItem (ExternalStorageManager.Device device) {
            this.device = device;

            var icon = new Gtk.Image.from_gicon(device.get_icon(), Gtk.IconSize.SMALL_TOOLBAR);
            set_label(device.name);
            debug("Label name: " + device.name);
            set_always_show_image(true);
            set_image(icon);
            set_sensitive(device.is_mounted);

            show_all();

            // Connect device signals
            activate.connect(on_activate);
            device.removed.connect(this.removed_device);
            device.updated.connect(this.update_values);
        }

        public void update_values () {
            debug("Changed");
            if(this != null)
                set_sensitive(device.is_mounted);
        }

        public void removed_device () {
            debug("Device removed destroy item");
            destroy();
        }

        public void on_activate(){
            debug("Activate");
            device.eject(this);
        }

    }
}


