/*

    External Storage Manager
    Copyright 2012, Jose Luis Navarro <jlnavarro111@gmail.com>

    This file is part of External Storage Manager.

    External Storage Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    External Storage Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with ExternalStorageManager.  If not, see <http://www.gnu.org/licenses/>.

*/

using Gtk;
using GLib;
using AppIndicator;
using Notify;

namespace ExternalStorageManager {

    const string DEVICE_IDENTIFIER = GLib.VolumeIdentifier.UNIX_DEVICE;
    bool show_internal = false;

    public class ExternalStorageManagerApp: Granite.Application {

        private AppIndicator.Indicator indicator;
        private GLib.VolumeMonitor monitor;
        private GLib.HashTable<string, ExternalStorageManager.Device> devices;
        private GLib.SList<string> invalid_devices;
        private Gtk.Menu menu;
        public Notify.Notification notification;

        construct{

            // App info
            build_data_dir = Build.DATADIR;
            build_pkg_data_dir = Build.PKG_DATADIR;
            build_release_name = Build.RELEASE_NAME;
            build_version = Build.VERSION;
            build_version_info = Build.VERSION_INFO;

            program_name = "External Storage Manager";
            exec_name = "external-extorage-manager";
            application_id = "org.external-extorage-manager";

            app_copyright = "2013";
            app_icon = "external-extorage-manager";
            app_launcher = "external-extorage-manager.desktop";
            app_years = "2012";

            main_url = "https://launchpad.net/external-extorage-manager";
            bug_url = "https://bugs.launchpad.net/external-extorage-manager";
            help_url = "https://answers.launchpad.net/external-extorage-manager";
            translate_url = "https://translations.launchpad.net/external-extorage-manager";

            about_authors = {"Jose L. Navarro <jlnavarro111@gmail.com>", null};
            about_artists = {"Jose L. Navarro <jlnavarro111@gmail.com>", null};

            about_comments = _("Indicator to manage external storage");
            about_translators = "Launchpad Translators";
            about_license_type = Gtk.License.GPL_3_0;
        }

        public ExternalStorageManagerApp() {
            Granite.Services.Logger.initialize("ExternalStorageManager");
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

            // AppIndicator
            this.indicator = new AppIndicator.Indicator("external-storage-manager", "external-storage-manager", AppIndicator.IndicatorCategory.HARDWARE);
            this.indicator.set_status(AppIndicator.IndicatorStatus.PASSIVE);

            // Main menu
            this.menu = new Gtk.Menu();

            // Device map
            this.devices = new GLib.HashTable<string , ExternalStorageManager.Device>(GLib.str_hash, GLib.str_equal);
            this.invalid_devices = new GLib.SList<string>();

            // GIO monitor
            this.monitor = GLib.VolumeMonitor.get();
            this.load_devices();

            // Watcher
            this.monitor.volume_added.connect((volume) => { manage_volume(volume); });
            this.monitor.mount_added.connect((mount) => { manage_mount(mount); });

            this.indicator.set_menu(this.menu);

            // Notification
            if (!Notify.is_initted()) Notify.init(application_id);
            this.notification = new Notify.Notification(" ", "", "external-storage-manager");
            this.notification.set_category("device");
            this.notification.set_urgency(Notify.Urgency.LOW);
        }

        public override void activate() {
            message("activate");
            //this.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
        }

        public void notify_new (ExternalStorageManager.Device device) {
            this.notification.update(_("%s").printf(device.name),
                                     _("Device ready."),
                                     "external-storage-manager");
            show_notification();
        }

        public void notify_unmounted (ExternalStorageManager.Device device) {
            this.notification.update(_("%s was unmounted").printf(device.name),
                                     _("The device was unmounted."),
                                     "external-storage-manager");
            show_notification();
        }

        public void notify_ejected (ExternalStorageManager.Device device) {
            this.notification.update(_("%s can be removed").printf(device.name),
                                     _("It's now possible to safely remove the device."),
                                     "external-storage-manager");
            show_notification();
        }

        public void show_notification () {
            try { this.notification.show(); }
            catch (GLib.Error error) {
                critical("** Error: %s\n", error.message);
            };
        }

        private void load_devices () {
            debug("Load devices");
            foreach (GLib.Volume v in (GLib.List<GLib.Volume>) monitor.get_volumes()) {
                manage_volume(v);
            }
            check_icon();
        }

        private void manage_mount(GLib.Mount mount){
            manage_volume(mount.get_volume());
        }

        private void manage_volume(GLib.Volume volume){
            message("NEW VOLUME");

            var id = volume.get_identifier(DEVICE_IDENTIFIER);
            if (id == null || id == "") { debug("No id"); return; }
            if (invalid_devices.index(id) >= 0) { debug("Skipped volume (in invalid list)"); return; }
            var dev = devices.lookup(id);
            if (dev != null) {
                debug("Device already in list (update info)");
                notify_new(dev);
                dev.update();
                return;
             }
            debug("Volume id: " + id);

            dev = new ExternalStorageManager.Device(volume);
            menu.prepend(new DeviceMenuItem(dev));
            devices.insert(id, dev);

            dev.unmounted.connect(dev => {
                notify_unmounted(dev);
            });

            dev.ejected.connect(dev => {
                notify_ejected(dev);
            });

            dev.removed.connect(dev => {
                        devices.remove(id);
                        this.check_icon();
                        notify_ejected(dev);
                        try {
                            this.notification.close(); //TODO no se pq lo hace
                        } catch (GLib.Error error) {
                            critical("** Error: %s\n", error.message);
                        }
                    });

            this.check_icon();
        }

        private void check_icon () {

            uint num = this.devices.size();

            if (num <= 0 && this.menu.visible) this.menu.popdown();

            if (num > 0) {
                this.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
            } else {
                try {
                    if (this.notification != null)
                        this.notification.close();
                } catch (GLib.Error error) {
                    critical("** Error: %s\n", error.message);
                }
                this.indicator.set_status(AppIndicator.IndicatorStatus.PASSIVE);
            }
        }

        static int main (string[] args) {
            Gtk.init(ref args);
            debug("main");
            GLib.Environment.set_application_name("external-storage-manager");

            var app = new ExternalStorageManagerApp();
            app.run(args);
            Gtk.main();
            return 0;
        }

    }

}

