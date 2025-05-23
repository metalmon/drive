<template>
  <Dialog v-model="open" :options="{ title: dialogData.title, size: 'sm' }">
    <template #body-content>
      <div class="flex items-center justify-start">
        <p class="text-base text-gray-600 leading-5">
          {{ dialogData.message }}
        </p>
      </div>
      <ErrorMessage class="my-1 text-center" :message="errorMessage" />
      <div class="flex mt-5">
        <Button
          :variant="dialogData.variant"
          :icon-left="dialogData.buttonIcon"
          :theme="dialogData.theme"
          class="w-full"
          :loading="$resources.method?.loading"
          @click="$resources.method.submit()"
        >
          {{ errorMessage ? "Try again" : dialogData.buttonMessage }}
        </Button>
      </div>
    </template>
  </Dialog>
</template>
<script>
import { Dialog, ErrorMessage } from "frappe-ui"
import { del } from "idb-keyval"
import { toast } from "@/utils/toasts.js"
import { mutate, getTrash } from "@/resources/files.js"

export default {
  name: "GeneralDialog",
  components: {
    Dialog,
    ErrorMessage,
  },
  props: {
    modelValue: {
      type: Boolean,
      required: true,
    },
    entities: {
      type: [Array, String],
      required: true,
    },
    for: {
      type: String,
      default: null,
    },
  },
  emits: ["update:modelValue", "success"],
  data() {
    return {
      errorMessage: "",
    }
  },

  computed: {
    dialogData() {
      const items =
        this.entities.length === 1
          ? `this item`
          : `${this.entities.length} items`
      switch (this.for) {
        case "unshare":
          return {
            title: "Unshare",
            message:
              "Selected items will not be shared with you anymore and you will lose access to them.",
            buttonMessage: "Remove",
            theme: "red",
            buttonIcon: "trash-2",
            methodName: "drive.api.files.unshare_entities",
            toastMessage: `Unshared ${items}`,
          }
        case "restore":
          return {
            title: "Restore Items",
            message:
              "Selected items will be restored to their original locations.",
            buttonMessage: "Restore",
            onSuccess: (e) =>
              getTrash.setData((d) => d.filter((k) => !e.includes(k.name))),
            variant: "solid",
            buttonIcon: "refresh-ccw",
            methodName: "drive.api.files.remove_or_restore",
            toastMessage: `Restored ${items}`,
          }
        case "remove":
          return {
            title: "Move to Trash",
            message:
              items[0].toUpperCase() +
              items.slice(1) +
              " will be moved to Trash. Items in trash are deleted forever after 30 days.",
            buttonMessage: "Move to Trash",
            mutate: (el) => (el.is_active = 0),
            theme: "red",
            variant: "subtle",
            buttonIcon: "trash-2",
            methodName: "drive.api.files.remove_or_restore",
            toastMessage: `Moved ${items} to Trash`,
          }
        default:
          return {}
      }
    },
    open: {
      get() {
        return this.modelValue === this.for
      },
      set(value) {
        this.$emit("update:modelValue", value)
      },
    },
  },
  resources: {
    method() {
      return {
        url: this.dialogData.methodName,
        makeParams: () => {
          this.$emit("success")
          return {
            entity_names:
              typeof this.entities === "string"
                ? JSON.stringify([this.entities])
                : JSON.stringify(this.entities.map((entity) => entity.name)),
            team: this.$route.params.team,
          }
        },
        onSuccess(data) {
          this.$emit("success", data)
          this.$resources.method.reset()
          this.entities.map((entity) => del(entity.name))
          if (this.dialogData.mutate)
            mutate(this.entities, this.dialogData.mutate)
          if (this.dialogData.onSuccess)
            this.dialogData.onSuccess(
              this.entities.map((entity) => entity.name)
            )
          toast({
            title: this.dialogData.toastMessage,
            position: "bottom-right",
            timeout: 2,
          })
        },
        onError(error) {
          if (error.messages) {
            this.errorMessage = error.messages.join("\n")
          } else {
            this.errorMessage = error.message
          }
        },
      }
    },
  },
}
</script>
