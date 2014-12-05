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

    public class Device: GLib.Object {

        public GLib.Volume volume {get; private set;}
        public bool is_system_internal {get; private set;}
        public bool is_mounted {get; private set;}
        public string name {get; private set;}
        public uint64 fs_capacity {get; private set;}
        public uint64 fs_free {get; private set;}
        private GLib.FileMonitor file_monitor;

        public signal void removed ();
        public signal void ejected ();
        public signal void unmounted ();
        public signal void updated ();

        public Device (GLib.Volume volume) {
            this.volume = volume;
            this.is_system_internal = true;

            this.is_mounted = volume.can_eject();

            if (volume.get_drive() == null)
                this.name = volume.get_name();
            else
                this.name = volume.get_name()+" (" + volume.get_drive().get_name() + ")";

            update();

            volume.removed.connect(volume_removed);
            volume.changed.connect(update);
        }

        private void volume_removed(){ removed(); }

        public void update(){
            debug("Describe device");
            var m = volume.get_mount();
            debug("Volume id: " + volume.get_identifier(DEVICE_IDENTIFIER));
            debug("Volume name: " + volume.get_name());
            var f = volume.get_activation_root(); //TODO si no esta montado no pasa de aqui
            if (null != f) debug("Volume activation root path: " + f.get_path());
            //is_mount_path_system_internal (string mount_path)
            if(null != m){
                is_mounted = true;
                m.changed.connect((mu) => { debug("Mount changed: "+ mu.get_name()); });
                debug("Mount name: " + m.get_name());
                var root = m.get_root();
                if (null != root){
                    debug("Mount root path: " + root.get_path());
                    try{
                        file_monitor = root.monitor_directory(FileMonitorFlags.NONE, null);
                        file_monitor.changed.connect( (file, other_file, event_type) => {
                         debug("file "+ file.get_path() +
                               " other_file: "+(other_file!=null?other_file.get_path():"")+
                               " event: "+event_type.to_string());
                         } );
                         //if (event_type == GLib.Volume.  G_FILE_MONITOR_EVENT_UNMOUNTED //TODO check if event is unmounted
                        var info = root.query_filesystem_info ("filesystem::*", null);
                        fs_capacity = info.get_attribute_uint64 (FileAttribute.FILESYSTEM_SIZE);
                        debug("Size: "+"%"+uint64.FORMAT_MODIFIER+"d", fs_capacity);
                        fs_free = info.get_attribute_uint64 (FileAttribute.FILESYSTEM_FREE);
                        debug("Free: "+"%"+uint64.FORMAT_MODIFIER+"d", fs_free);
                    }catch (GLib.Error e){
                        critical("Error query filesystem: " + e.message);
                    }
                }
            }else{
                fs_capacity = 0;
                fs_free = 0;
                is_mounted = !volume.can_mount();
            }
            updated();
        }

        public GLib.Icon get_icon(){
            var m = volume.get_mount();
            if (null != m){
                return m.get_icon();
            }else{
                return volume.get_icon();
            }
        }

        public async void eject (Gtk.MenuItem menuitem) {
            Gtk.MountOperation op = new Gtk.MountOperation(null);

            if (this.volume.can_eject()) {
                debug("Eject: " + this.name);
                try {
                    if (yield volume.eject_with_operation(GLib.MountUnmountFlags.NONE, op)) {
                        debug("EJECT OK");
                        removed();
                        menuitem.destroy();
                    } else {
                        debug("EJECT FAILED");
                    }
                } catch (GLib.Error err) {
                    critical("EJECT ERROR: "+err.message);
                }
            } else if (volume.get_drive() != null){
                debug("Unmount: " + this.name);
                try {
                    var m = volume.get_mount();
                    if (m.can_eject()){
                        if (yield m.eject_with_operation(GLib.MountUnmountFlags.NONE, op)) {
                            debug("EJECT 2 OK");
                            update();
                        } else {
                            debug("EJECT 2 FAILED");
                        }
                    }else if (m.can_unmount()){
                        if (yield m.unmount_with_operation(GLib.MountUnmountFlags.NONE, op)) {
                            debug("UNMOUNT OK");
                            unmounted();
                            update();
                        } else {
                            debug("UNMOUNT FAILED");
                        }
                    }
                } catch (GLib.Error err2) { //TODO falla al desmontar un solo volumen
                    critical("UNMOUNT ERROR: "+err2.message);
                }
            }
        }

    }
}


