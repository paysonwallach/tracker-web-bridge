/*
 * Copyright (c) 2020 Payson Wallach
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

namespace TrackerWeb {
    public enum Method {
        EVENT,
        GET_HASH,
        UPDATE_STORE,
        CHECK_HASHES,
        GET_PAGE_DATA;

        public static Method from_string (string @value) {
            switch (@value) {
            case "event":
                return EVENT;
            case "get-hash":
                return GET_HASH;
            case "update-store":
                return UPDATE_STORE;
            case "check-hashes":
                return CHECK_HASHES;
            case "get-page-data":
                return GET_PAGE_DATA;
            default:
                assert_not_reached ();
            }
        }

        public string to_string () {
            switch (this) {
            case EVENT:
                return "event";
            case GET_HASH:
                return "get-hash";
            case UPDATE_STORE:
                return "update-store";
            case CHECK_HASHES:
                return "check-hashes";
            case GET_PAGE_DATA:
                return "get-page-data";
            default:
                assert_not_reached ();
            }
        }
    }

    public class Message : Serializable {
        [CCode (cname = "apiVersion")]
        public string api_version { get; construct set; }

        public string id { get; construct set; }

        public Method method { get; construct set; }

        public string? context { get; construct set; }

        public Message (Method method, string? context = null) {
            this.api_version = Config.API_VERSION;
            this.id = Uuid.string_random ();
            this.method = method;
            this.context = context;
        }
    }

    public class Event : Message {
        public string name { get; construct set; }

        public Event (string name) {
            base (Method.EVENT);

            this.name = name;
        }
    }

    public class Error : Serializable {
        public int code { get; construct set; }

        public string description { get; construct set; }

        public Error (int code, string description) {
            this.code = code;
            this.description = description;
        }
    }

    public class GetHashRequest : Message {
        [CCode (cname = "tabId")]
        public string tab_id { get; construct set; }

        public string url { get; construct set; }

        public GetHashRequest (string tab_id, string url) {
            base (Method.GET_HASH);

            this.tab_id = tab_id;
            this.url = url;
        }
    }

    public class GetHashResultData : Serializable {
        public string hash { get; construct set; }

        public GetHashResultData (string? hash = "") {
            this.hash = hash;
        }
    }

    public class GetHashResult : Message {
        public GetHashResultData? data { get; construct set; }

        public Error? error { get; construct set; }

        public GetHashResult () {
            base (Method.GET_HASH);
        }

        public GetHashResult.with_success (string context, GetHashResultData data) {
            base (Method.GET_HASH, context);

            this.data = data;
        }

        public GetHashResult.with_error (string context, Error error) {
            base (Method.GET_HASH, context);

            this.error = error;
        }
    }

    public class CheckHashesRequest : Message {
        public string hash { get; construct set; }

        public CheckHashesRequest (string hash) {
            base (Method.CHECK_HASHES);

            this.hash = hash;
        }
    }

    public class CheckHashesResult : Message {
        public int difference { get; construct set; }

        public CheckHashesResult (int difference) {
            base (Method.CHECK_HASHES);

            this.difference = difference;
        }
    }

    public class GetPageDataRequest : Message {
        public GetPageDataRequest () {
            base (Method.GET_PAGE_DATA);
        }
    }

    public class PageData : Serializable {
        public string title { get; construct set; }

        public string excerpt { get; construct set; }

        [CCode (cname = "textContent")]
        public string text_content { get; construct set; }

        public PageData (string title, string excerpt, string text_content) {
            this.title = title;
            this.excerpt = excerpt;
            this.text_content = text_content;
        }
    }

    public class GetPageDataResultData : Serializable {
        public string hash { get; construct set; }

        public PageData page { get; construct set; }

        public GetPageDataResultData (string hash, PageData page) {
            this.hash = hash;
            this.page = page;
        }
    }

    public class GetPageDataResult : Message {
        public GetPageDataResultData? data { get; construct set; }

        public Error? error { get; construct set; }

        public GetPageDataResult () {
            base (Method.GET_PAGE_DATA);
        }

        public GetPageDataResult.with_success (GetPageDataResultData data) {
            base (Method.GET_PAGE_DATA);

            this.data = data;
        }

        public GetPageDataResult.with_error (Error error) {
            base (Method.GET_PAGE_DATA);

            this.error = error;
        }
    }

    public class UpdateStoreRequestData : GetPageDataResultData {
        public UpdateStoreRequestData (string hash, PageData data) {
            base (hash, data);
        }
    }

    public class UpdateStoreRequest : Message {
        public UpdateStoreRequestData data { get; construct set; }

        public UpdateStoreRequest (UpdateStoreRequestData data) {
            base (Method.UPDATE_STORE);

            this.data = data;
        }
    }

    public class UpdateStoreResultData : Serializable {
        public bool success { get; construct set; }

        public UpdateStoreResultData (bool success) {
            this.success = success;
        }
    }

    public class UpdateStoreResult : Message {
        public UpdateStoreResultData? data { get; construct set; }

        public Error? error { get; construct set; }

        public UpdateStoreResult () {
            base (Method.UPDATE_STORE);
        }

        public UpdateStoreResult.with_success (UpdateStoreResultData data) {
            base (Method.UPDATE_STORE);

            this.data = data;
        }

        public UpdateStoreResult.with_error (Error error) {
            base (Method.UPDATE_STORE);

            this.error = error;
        }
    }
}
