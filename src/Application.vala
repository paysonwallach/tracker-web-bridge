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

errordomain QueryError {
    RESOURCE_NOT_FOUND
}

public class TrackerWeb.Application : GLib.Application {
    private const Tracker.Sparql.ConnectionFlags connection_flags =
        Tracker.Sparql.ConnectionFlags.FTS_ENABLE_STEMMER |
        Tracker.Sparql.ConnectionFlags.FTS_ENABLE_UNACCENT |
        Tracker.Sparql.ConnectionFlags.FTS_ENABLE_STOP_WORDS |
        Tracker.Sparql.ConnectionFlags.FTS_IGNORE_NUMBERS;

    private ExtensionProxy extension;
    private Tracker.Sparql.Connection connection;

    public Application () throws GLib.Error {
        hold ();

        connection = Tracker.Sparql.Connection.new (
            connection_flags,
            File.new_build_filename (
                Environment.get_user_cache_dir (), Config.APP_ID),
            Tracker.Sparql.get_ontology_nepomuk (),
            null);
        info ("database initialized");
        extension = ExtensionProxy.get_default ();

        extension.message_received.connect (on_message_received);
        extension.start_listening.begin ();
        info ("listening...");
    }

    public void terminate () {
        release ();
    }

    private void on_message_received (string message) {
        Message deserialized_message;
        Message? response = null;
        try {
            deserialized_message = Json.gobject_from_data (typeof (Message), message) as Message;
        } catch (GLib.Error err) {
            warning (err.message);
            return;
        }

        debug (@"method: $(deserialized_message.method)");
        var context = "unknown";
        switch (deserialized_message.method) {
        case Method.GET_HASH:
            GetHashRequest request;
            try {
                request = Json.gobject_from_data (
                    typeof (GetHashRequest), message) as GetHashRequest;
                context = request.tab_id;

                var query = (
                    "SELECT ?hashValue " +
                    "WHERE { " +
                    "  ?dataObject a nie:DataObject . " +
                    "  ?dataObject nie:url '%s' . " +
                    "  ?dataObject nfo:hasHash ?hash . " +
                    "  ?hash a nfo:FileHash . " +
                    "  ?hash nfo:hashValue ?hashValue " +
                    "}").printf (
                    request.url);

                var cursor = connection.query (query);

                if (!cursor.next ())
                    throw new QueryError.RESOURCE_NOT_FOUND (
                              @"unable to locate a record associated with the requested url: $(request.context) ");

                var hash = cursor.get_string (0);
                info (@"hash: $hash");
                var data = new GetHashResultData (hash);

                response = new GetHashResult.with_success (context, data);
            } catch (GLib.Error e) {
                var err = new Error (e.code, e.message);
                response = new GetHashResult.with_error (context, err);
            }
            break;
        case Method.UPDATE_STORE:
            UpdateStoreRequest request;
            try {
                request = Json.gobject_from_data (
                    typeof (UpdateStoreRequest), message) as UpdateStoreRequest;

                var query = (
                    "SELECT ?dataObject " +
                    "WHERE { " +
                    "  ?dataObject a nie:DataObject . " +
                    "  ?dataObject nie:url '%s' " +
                    "}").printf (
                    request.context);

                var cursor = connection.query (query);

                if (cursor.next ()) {
                    var data_resource_object_urn = cursor.get_string (0);

                    query = (
                        "SELECT ?hash " +
                        "WHERE { " +
                        "  '%s' nfo:hasHash ?hash . " +
                        "  ?hash a nfo:FileHash" +
                        "}").printf (
                        data_resource_object_urn);
                    cursor = connection.query (query);

                    if (!cursor.next ())
                        throw new QueryError.RESOURCE_NOT_FOUND (@"unable to locate hash for resource $data_resource_object_urn");

                    var file_hash_resource_urn = cursor.get_string (0);

                    set_triple (file_hash_resource_urn, "nfo:hashValue", request.data.hash);

                    query = (
                        "SELECT ?website " +
                        "WHERE { " +
                        "  ?website nie:isStoredAs '%s' . " +
                        "  ?website a nfo:Website " +
                        "}").printf (
                        data_resource_object_urn);
                    cursor = connection.query (query);

                    if (!cursor.next ())
                        throw new QueryError.RESOURCE_NOT_FOUND (@"unable to locate website for resource $data_resource_object_urn");

                    var website_resource_urn = cursor.get_string (0);

                    set_triple (website_resource_urn, "nie:title", request.data.page.title);
                    set_triple (website_resource_urn, "nie:description", request.data.page.excerpt);
                    set_triple (website_resource_urn, "nie:plainTextContent", request.data.page.text_content);
                } else {
                    var hash_resource = new Tracker.Resource (null);

                    hash_resource.set_uri ("rdf:type", "nfo:FileHash");
                    hash_resource.set_string ("nfo:hashValue", request.data.hash);
                    hash_resource.set_string ("nfo:hashAlgorithm", "tlsh");

                    var data_object_resource = new Tracker.Resource (null);
                    info (@"context: $(request.context)");

                    data_object_resource.set_uri ("rdf:type", "nfo:RemoteDataObject");
                    data_object_resource.set_string ("nie:url", request.context);
                    data_object_resource.set_relation ("nfo:hasHash", hash_resource);

                    var resource = new Tracker.Resource (null);

                    resource.set_uri ("rdf:type", "nfo:Website");
                    resource.set_string ("nie:title", request.data.page.title);
                    resource.set_string ("nie:description", request.data.page.excerpt);
                    resource.set_string ("nie:plainTextContent", request.data.page.text_content);
                    resource.set_relation ("nie:isStoredAs", data_object_resource);

                    var resource_sparql_update = resource.print_sparql_update (null, null);
                    info (resource_sparql_update);
                    connection.update (resource_sparql_update);
                }

                response = new UpdateStoreResult.with_success (
                    new UpdateStoreResultData (true));
            } catch (GLib.Error e) {
                var err = new Error (e.code, e.message);
                response = new UpdateStoreResult.with_error (err);
            }
            break;
        default:
            break;
        }

        if (response == null)
            return;

        var serialized_response = Json.gobject_to_data (response, null);

        info (@"response: $serialized_response");
        ExtensionProxy.get_default ().send_message.begin (serialized_response);
    }

    private bool set_triple (string resource, string predicate, string property) {
        try {
            var delete_query = (
                "DELETE {" +
                "  <%s> %s ?val" +
                "} WHERE {" +
                "  <%s> %s ?val" +
                "}").printf (
                resource, predicate,
                resource, predicate);
            connection.update (delete_query);
            var insert_query = (
                "INSERT OR REPLACE { " +
                "  <%s> a nie:InformationElement, nie:DataObject ; %s '%s' " +
                "}").printf (
                resource, predicate, Tracker.Sparql.escape_string (property));
            info (@"query: $insert_query");
            connection.update (insert_query);
        } catch (GLib.Error err) {
            warning (err.message);
            return false;
        }

        return true;
    }

}
