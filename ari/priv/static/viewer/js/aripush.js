$(document).ready(function () {
    // Get current URL and base URL
    let currentUrl = window.location.href;
    let baseUrl = currentUrl.split('/index.html')[0];
    let authReady = false;

    const sessionOverlay = $('#session-overlay');
    const sessionOverlayTitle = $('#session-overlay-title');
    const sessionOverlayText = $('#session-overlay-text');

    function loginUrl(reason) {
        const next = window.location.pathname + window.location.search + window.location.hash;
        return '/login?next=' + encodeURIComponent(next) + '&reason=' + encodeURIComponent(reason || 'expired');
    }

    function showSessionOverlay(title, text, withSpinner) {
        sessionOverlay.removeClass('is-hidden');
        sessionOverlayTitle.text(title);
        sessionOverlayText.text(text);

        const spinner = sessionOverlay.find('.spinner-border');
        if (withSpinner === false) {
            spinner.addClass('d-none');
        } else {
            spinner.removeClass('d-none');
        }
    }

    function hideSessionOverlay() {
        sessionOverlay.addClass('is-hidden');
    }

    function redirectToLogin(reason) {
        showSessionOverlay('Session unavailable', 'Redirecting to the sign-in form.', false);
        window.setTimeout(function () {
            window.location.href = loginUrl(reason);
        }, 1200);
    }

    function handleUnauthorized() {
        if (!authReady) {
            showSessionOverlay('Session expired', 'You need to sign in again to open the Viewer.', false);
            window.setTimeout(function () {
                window.location.href = loginUrl('expired');
            }, 1400);
            return;
        }

        redirectToLogin('expired');
    }

    // Deactivate module for handling filter deactivation
    let deactivate = {
        // Initialize the deactivation module
        init: function () {
            // Get all filter inputs and select elements
            let filter = $('#filter input, #filter select');
            // Check filters initially
            this.checkFilter();
            // Add change event listener to each filter element
           // filter.each((index, element) => {
           //     // Bind the checkFilter function to the change event
           //     $(element).on('change', deactivate.checkFilter.bind(deactivate));
           // });
        },
        // Check the status of filters and update UI accordingly
        checkFilter: function () {
            // Get all filter inputs and select elements
            let filterInputs = $('#filter input, #filter select');
            // Flag to track if any filter field is filled
            let isAnyFieldFilled = false;

            // Iterate over each filter element
            filterInputs.each((index, element) => {
                // Check if the element is a checkbox
                if (element.type === 'checkbox') {
                    // Handle the 'active' checkbox separately
                    if (element.id === 'active') {
                        // Show or hide messages based on checkbox status
                        if ($(element).is(':checked')) {
                            $('#deactivateMessage').show();
                            $('#activateMessage').hide();
                        } else {
                            $('#deactivateMessage').hide();
                            $('#activateMessage').show();
                        }
                    } else {
                        // Update flag if any other checkbox is checked
                        if ($(element).prop('checked')) {
                            isAnyFieldFilled = true;
                        }
                    }
                } else if (element.value.trim() !== '') {
                    // Update flag if any non-checkbox input is filled
                    isAnyFieldFilled = true;
                }
            });

            if ($('#list').dataTable().fnGetData().length === 0) {
                isAnyFieldFilled = false;
            }

            // Disable or enable messages based on filter status
            $('#deactivateMessage').prop('disabled', !isAnyFieldFilled);
            $('#activateMessage').prop('disabled', !isAnyFieldFilled);
        }
    };

    // Viewer object for handling the Messages tab
    let viewer = {
        // DataTable initialization and customization
        table: $('#list').on('xhr.dt', function (e, settings, json) {
            // Modifying the JSON response data
            for (var i = 0, ien = json.data.length; i < ien; i++) {
                // Modifying request_type based on the response properties
                json.data[i].request_type = '';
                if (json.data[i].rate === 't') {
                    json.data[i].request_type = 'HotelRatePlanNotifRQ';
                }
                if (json.data[i].inventory === 't') {
                    json.data[i].request_type = 'HotelInvCountNotifRQ';
                }
                if (json.data[i].availability === 't') {
                    json.data[i].request_type = 'HotelAvailNotifRQ';
                }
            }
        }).dataTable({
            // DataTable configuration options
            "bFilter": false,
            "processing": true,
            "serverSide": true,
            "bSort": false,
            "lengthMenu": [10, 20, 50],
            "ajax": {
                "url": '/viewer/messages',
                "error": function (xhr) {
                    if (xhr.status === 401) {
                        handleUnauthorized();
                    }
                },
                "data": (request, object, d) => {
                    // Delete unnecessary properties from the request object
                    delete request.columns;
                    delete request.order;
                    delete request.search;

                    // Set values from URL parameters to form fields if the parameters exist
                    let urlParams = new URLSearchParams(window.location.search);
                    let formFields = [
                        'hotelCode', 'endDate', 'startDate', 'type', 'checksum',
                        'internalId', 'outsideId', 'user', 'startCreatedAt',
                        'endCreatedAt', 'startUpdatedAt', 'endUpdatedAt'
                    ];

                    formFields.forEach((field) => {
                        const paramValue = urlParams.get(field);
                        if (paramValue) {
                            $(`#${field}`).val(paramValue);
                        }
                    });

                    const booleanFields = ['double', 'error', 'active'];
                    booleanFields.forEach((field) => {
                        const paramValue = urlParams.get(field);
                        if (paramValue) {
                            $(`#${field}`).prop('checked', paramValue === 'true');
                        }
                    });

                    // Update the request object with the form values
                    formFields.forEach((field) => {
                        request[field] = $(`#${field}`).val();
                    });

                    booleanFields.forEach((field) => {
                        request[field] = $(`#${field}`).prop('checked')
                    })

                    for (let key in request) {
                        if (request.hasOwnProperty(key) && request[key]) {
                            urlParams.set(key, request[key]);
                        }
                    }

                    const newURL = `${baseUrl}/index.html?${urlParams.toString()}`;
                    //deactivate.checkFilter();
                    history.replaceState({}, '', newURL);
                }
            },
            "createdRow": (row, data) => {
                // Highlighting duplicates and errors
                if (data.double === 't') {
                    $(row).addClass('table-warning');
                }
                if (data.error === 't') {
                    $(row).addClass('table-danger')
                }
            },
            "drawCallback": () =>  {
                deactivate.checkFilter();
            },
            "columnDefs": [
                // Column definitions
                {
                    "targets": [0],
                    "render": (data, type, row, meta) => {
                        return 'Hotel Code: <span class="value">' + row.code + '</span><br>' +
                            'Request Type: <span class="value">' + row.request_type + '</span><br>' +
                            'Checksum: <span class="value">' + row.checksum + '</span>'
                    }
                },
                {
                    "targets": [1],
                    "render": (data, type, row, meta) => {
                        return 'Username: <span class="value">' + row.user + '</span><br>' +
                            'Message Time (GMT):  <span class="value badge bg-light text-dark">' + row.time_stamp + '</span><br>' +
                            'Message ID: <span class="value">' + row.outside_id + '</span>';
                    }
                }, {

                    "targets": [2],
                    "render": (data, type, row, meta) => {
                        return 'Received Time (Europe/Berlin): <span class="value badge bg-light text-dark">' + row.created_at + '</span><br>' +
                            'Response Time (Europe/Berlin): <span class="value badge bg-light text-dark">' + row.updated_at + '</span><br>' +
                            'Response Message ID: <span class="value">' + row.internal_id + '</span>';
                    }
                }
            ],
            "columns": [
                // Column definitions
                {"data": "request_type", class: "text-left"},
                {"data": "user", class: "text-left"},
                {"data": "internal_id", class: "text-left"},
                {
                    // Custom column with buttons
                    "data": null,
                    "class": "text-center",
                    "defaultContent": "<div class=\"row\">\n" +
                        "    <div class=\"col-12\">\n" +
                        "        <button type=\"button\" data-action=\"request\" class=\"btn btn-primary btn-table\"><i class=\"fas fa-file-alt\"></i>  View Request</button>\n" +
                        "    </div>\n" +
                        "</div>\n" +
                        "<div class=\"row mt-1\">\n" +
                        "    <div class=\"col-12\">\n" +
                        "        <button type=\"button\" data-action=\"response\" class=\"btn btn-primary btn-table\"><i class=\"fas fa-reply\"></i>View Response</button>\n" +
                        "    </div>\n" +
                        "</div>"
                }
            ]
        }),
        // Method for updating URL parameter
        updateURLParameter: function (paramName, newValue) {
            let urlParams = new URLSearchParams(window.location.search);
            urlParams.set(paramName, newValue);
            let newURL = `${baseUrl}/index.html?${urlParams.toString()}`;
            history.replaceState({}, '', newURL);
        },
        handleDeactivationConfirmation(e) {
            e.preventDefault();

            if ('deactivateMessage' === e.target.id) {
                $('#deactivateMessagesModal').modal('show');
            }
            if ('activateMessage' === e.target.id) {
                $('#activateMessagesModal').modal('show');
            }
        },
        setActive: function (e){
            e.preventDefault()
            let urlParams = new URLSearchParams(window.location.search);
            let self = this;
            urlParams.set('action', 'deactivate');
            $.ajax({
                url: '/viewer/messages/active',
                type: 'POST',
                data: urlParams.toString(),
                success: function(response) {
                    if (response.success) {
                        self.table.api().ajax.reload();
                        $('#deactivateMessagesModal').modal('hide');
                        $('#activateMessagesModal').modal('hide');
                    }
                }
            });

        },
        // Initialization function for handling events and actions
        init: function () {
            // Initializing event handlers and actions
            let dataTable = $('#list tbody');
            let self = this;
            let booleanFields = ['double', 'error', 'active'];
            let formFields = [
                'endDate', 'hotelCode', 'startDate', 'checksum', 
                'startCreatedAt', 'endCreatedAt', 'startUpdatedAt', 
                'endUpdatedAt', 'type', 'internalId', 'outsideId', 'user'
            ];

            // Initialize filter deactivation
            deactivate.init();

            // Event handler for checkbox change
            const handleCheckboxChange = function (fieldName) {
                return function () {
                    let isChecked = $(this).prop('checked');
                    self.updateURLParameter(fieldName, isChecked ? 'true' : 'false');
                    self.table.api().ajax.reload();
                };
            };

            // Bind checkbox change event for each boolean field
            booleanFields.forEach((field) => {
                $(`#${field}`).on('change', handleCheckboxChange(field))
            })

            // Event handler for clear button
            $("#clear").on('click', (e) => {
                e.preventDefault();
                let newURL = window.location.pathname;
                $('#show-errors').prop('checked', false);
                $('#show-duplicates').prop('checked', false);
                history.replaceState({}, '', newURL);
                $('#filter')[0].reset();
                self.table.api().ajax.reload();
            });

            // Event handler for search button
            $('#search').on('click', (e) => {
                e.preventDefault();
                self.table.api().ajax.reload();
            });

            $('#activateMessage').on('click', this.handleDeactivationConfirmation.bind(this));
            $('#deactivateMessage').on('click', this.handleDeactivationConfirmation.bind(this));
            $('#confirmDeactivation').on('click', this.setActive.bind(this))
            $('#confirmActivation').on('click', this.setActive.bind(this))

            // Event handler for form field change
            formFields.forEach((field) => {
                $(`#${field}`).on('change', (e) => {
                    let value = $(e.target).val();
                    this.updateURLParameter(field, value);
                })
            })

            // Event delegation for button click inside the table
            dataTable.on('click', 'button[data-action]', (e) => {
                e.preventDefault();
                let data = self.table.api().row(e.target.closest('tr')).data();
                let button = e.target.closest('button[data-action]');
                let url = '/viewer/payload/' + button.getAttribute('data-action') + '/' + data.id;
                window.open(url, '_blank');
            });
        }
    };

    // UsersViewer object for handling the Users tab
    let usersViewer = {
        // DataTable initialization and customization
        table: $('#users-list').dataTable({
            // DataTable configuration options
            "bFilter": false,
            "processing": true,
            "serverSide": true,
            "bSort": false,
            "ajax": {
                "url": '/viewer/users',
                "error": function (xhr) {
                    if (xhr.status === 401) {
                        handleUnauthorized();
                    }
                },
                "data": (request) => {
                    // Setting request data from form inputs
                    delete request.columns;
                    delete request.order;
                    request.name = $('#filter-name').val();
                    request.customerCode = $('#filter-customerCode').val();
                }
            },
            "columns": [
                // Column definitions
                {"data": "id"},
                {"data": "name"},
                {"data": "code"},
                {"data": "created_at"},
                {
                    // Custom column with button
                    "data": null,
                    "class": "text-center",
                    "defaultContent":
                        '<button type="button" data-action="deleteUser" class="btn btn-danger btn-sm">' +
                        '<i class="fas fa-user-slash""></i> Delete ' +
                        '</button>'
                }
            ]
        }),
        // Error handling functions
        errors: function () {
            return {
                clearById: function (id) {
                    // Clear error feedback for a specific element
                    $('#feedback_' + id).html('');
                    $('#' + id).removeClass('is-invalid');
                },
                clearAll: function () {
                    // Clear error feedback for all elements and reset values
                    $('#create-user-form :input:not(:button)').each((index, element) => {
                        this.clearById(element.id);
                        element.value = '';
                    });
                }
            };
        },
        // Create user function
        create: function () {
            let self = this;
            let formData = $('#create-user-form').serialize();
            $.ajax({
                url: '/viewer/users',
                method: 'POST',
                data: formData,
                success: function (response) {
                    // Handle response
                    if (response.success === false && response.errors) {
                        let errors = response.errors;
                        let entries = Object.entries(errors);
                        for (const [id, error] of entries) {
                            $('#feedback_' + id).html(error);
                            $('#' + id).addClass('is-invalid');
                        }
                    }
                    if (response.success === true) {
                        $('#createUserModal').modal('hide');
                        self.table.api().ajax.reload();
                    }
                }
            });
        },
        // Generate a random password
        generatePassword: function (length) {
            const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            let password = "";
            for (let i = 0; i < length; i++) {
                const randomIndex = Math.floor(Math.random() * charset.length);
                password += charset[randomIndex];
            }
            return password;
        },
        // Delete user function
        delete: function (id) {
            let self = this;
            $.ajax({
                url: '/viewer/users/' + id,
                method: 'DELETE',
                success: function (response) {
                    if (response.success === true) {
                        self.table.api().ajax.reload();
                        $("#confirmationModal").modal('hide');
                    }
                }
            });
        },
        // Initialization function for handling events and actions
        init: function () {
            let dataTable = $('#users-list tbody');
            let self = this;
            let generatePassword = $("#generatePassword");
            let copyPassword = $("#copyPassword");

            // Event handler for generating password
            generatePassword.tooltip({
                title: "Generate password"
            });
            copyPassword.tooltip({
                title: "Copy password to clipboard"
            });

            generatePassword.on("click", function (e) {
                e.preventDefault();
                $("#password").val(usersViewer.generatePassword(12));
            });

            copyPassword.on("click", function (e) {
                e.preventDefault();
                const password = $("#password").val();

                navigator.clipboard.writeText(password)
                    .then(() => {
                    })
                    .catch((error) => {
                        console.log(error)
                    });
            });

            // Event handler for modal close and form input changes
            $('#createUserModal').on('hide.bs.modal', () => {
                self.errors().clearAll();
            });
            $('#createUserModal .btn-close').on('click', () => {
                self.errors().clearAll()
            });
            $('#create-user-form :input:not(:button)').each((index, element) => {
                $(element).on('input', (e) => {
                    self.errors().clearById(e.target.id)
                });
            });

            // Event handlers for search and clear buttons
            $('#user-search').on('click', (e) => {
                e.preventDefault();
                self.table.api().ajax.reload();
            });
            $('#create-users').on('click', (e) => {
                e.preventDefault();
                self.create()
            });
            $('#user-clear').on('click', (e) => {
                e.preventDefault();
                $('#user-filter')[0].reset();
            });

            // Event handler for delete button
            $('#deleteUser').on('click', (e) => {
                e.preventDefault();
                let id = localStorage.getItem('user_id');
                self.delete(id);
            });

            // Event delegation for delete user button inside the table
            dataTable.on('click', 'button[data-action=deleteUser]', (e) => {
                e.preventDefault();
                $("#confirmationModal").modal('show');
                let data = self.table.api().row(e.target.closest('tr')).data();
                localStorage.setItem('user_id', data.id);
            });

            // Event handler for opening create user modal
            $('#createUser').on('click', (e) => {
                e.preventDefault();
                $("#createUserModal").modal('show');
            })
        }
    };

    function bootstrapViewer() {
        showSessionOverlay('Checking session', 'Preparing the Viewer interface.', true);

        $.ajax({
            url: '/api/session',
            method: 'GET',
            success: function () {
                authReady = true;
                hideSessionOverlay();
                viewer.init();
                usersViewer.init();
            },
            error: function (xhr) {
                if (xhr.status === 401) {
                    handleUnauthorized();
                    return;
                }

                showSessionOverlay('Initialization error', 'Could not verify the session. Refresh the page or sign in again.', false);
            }
        });
    }

    bootstrapViewer();
});
